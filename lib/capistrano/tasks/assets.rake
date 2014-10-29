namespace :assets do
  desc 'Deploy all gems'
  task :deploy_all do
    reinvoke :'assets:before'
    releases.each do |release|
      set :release, release
      reinvoke :'assets:deploy'
    end
    reinvoke :'assets:symlink'
    reinvoke :'assets:legacy'
    reinvoke :'assets:cleanup'
    reinvoke :'assets:after'
  end

  desc 'Deploy some release'
  task :deploy do
    reinvoke :'assets:before'
    ask(:release, releases.last) unless fetch(:release) || ENV['RELEASE']
    release = fetch(:release) || ENV['RELEASE']

    unless releases.include?(release)
      puts "Release #{release} not found"
      next
    end

    set :assets_current_release, release
    set :assets_release_path, fetch(:assets_releases_path).join(release)

    puts "Build release #{fetch(:assets_current_release)}"
    set :branch, fetch(:assets_current_release)
    puts "Release target #{fetch(:assets_release_path)}"
    #Make release
    reinvoke :'assets:checkout'
    reinvoke :'assets:build'
    reinvoke :'assets:symlink'
    reinvoke :'assets:cleanup'
    reinvoke :'assets:after'
  end

  desc 'Build assets'
  task :build do
    reinvoke :'assets:before'
    on roles(:assets), in: :parallel do
      if test("[ -d #{fetch(:assets_release_path)} ]") && !ENV['FORCE']
        puts "Release #{fetch(:assets_current_release)} exist"
        next
      end
      puts 'Run build command in project release path'
      within release_path do
        Array(fetch(:assets_build_commands, [])).each do |command|
          execute(*command.split(/\s/))
        end
      end
      puts 'Copy assets to assets release path'
      execute('mkdir', '-p', fetch(:assets_release_path))
      fetch(:assets_build_path).each do |assets_path|
        execute('cp', '-r', "#{assets_path}/*", "#{fetch(:assets_release_path)}/")
      end
    end
    reinvoke :'assets:after'
  end

  desc 'Make symlinks to last and pre releases'
  task :symlink do
    reinvoke :'assets:before'
    stable = releases.reject { |r| r.include?('pre') }
    symlinks = {}
    symlinks['last'] = stable.last
    symlinks['pre'] = releases.reject { |r| !r.include?('pre') }.last
    symlinks.merge! stable.group_by { |v| "#{v.split('.').first}.last" }
    symlinks.merge! stable.group_by { |v| "#{v.split('.')[0..-2].join('.')}.last" }
    on roles(:assets), in: :parallel do
      execute("cd #{fetch(:assets_releases_path)} && find . -maxdepth 1 -type l -exec rm {} \\;")
      symlinks.each do |m, v|
        v = v.last if v.is_a?(Array)
        execute("if test -d #{fetch(:assets_releases_path).join(v)}; then ln -sf #{fetch(:assets_releases_path).join(v)} #{fetch(:assets_releases_path).join(m)}; fi;") if v
      end
      execute("if test -d #{fetch(:assets_releases_path)}; then ln -sf #{fetch(:assets_releases_path)} #{fetch(:assets_symlink)}; fi;") if fetch(:assets_symlink)
    end
    reinvoke :'assets:after'
  end

  task :checkout do
    #clean temp directory
    reinvoke :'assets:before'
    reinvoke :'assets:cleanup'
    reinvoke :'git:clone'
    reinvoke :'git:create_release'
    reinvoke :'bundler:install'
    reinvoke :'assets:after'
  end

  task :before do
    set :_release_path, fetch(:release_path) #save old release_path
    set :release_path, shared_path.join('tmp/assets')
    set :assets_releases_path, deploy_path.join(Pathname.new(fetch(:assets_releases_dir, 'shared/assets')))
    set :assets_build_path, Array(fetch(:assets_build_dir, 'build')).map { |dir| release_path.join(Pathname.new dir) }
  end

  task :after do
    set :release_path, fetch(:_release_path)
  end

  task :cleanup do
    on roles(:assets), in: :parallel do
      execute("rm -rf -- #{release_path}")
    end
  end
end

def reinvoke(task, *args)
  Rake.application[task].reenable
  invoke(task, *args)
end

def releases
  @_releases ||= `git ls-remote --tags #{fetch(:repo_url)}`.split("\n").map { |t| t.split(' ').last.split('/').last if t.include?('refs/tags') && !t.include?('^{}') }.compact.sort { |x, y| Gem::Version.new(x) <=> Gem::Version.new(y) }
end
