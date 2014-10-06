

Gemfile

    group :development do
      gem 'capistrano', '~> 3.1.0', require: false
      gem 'capistrano-rvm', require: false
      gem 'capistrano-bundler', '~> 1.1.2', require: false
      gem 'capistrano-assets', github: 'MurgaNikolay/capistrano_assets', require: false
    end

Capfile

    #depends on what you need to build
    #require 'capistrano/rvm'
    # require 'capistrano/rbenv'
    # require 'capistrano/chruby'
    # require 'capistrano/bundler'
    require 'capistrano/assets' 
        
deploy.rb

    #Set git tag for assets version
    #Public folder for assets, for example
    
    set :application, 'my_application'
    set :repo_url, 'git@github.com:my_acount/my_papplication.git'
 
    set :assets_build_dir, 'tmp/build' #grunt assets build or assets folder
    #command fo build assets
    set :assets_build_commands, [
      'npm install',
      'bundle exec grunt'
    ]
    
stages/production.rb

    server 'cdn.assets.example.com', user: 'deploy', roles: %w{assets}
    set :deploy_to, '/var/www/access'
    set :assets_symlink, '/var/www/assets/public/assets' #nginx root /var/www/assets/public;
    
    #deploy some version (version will be requested)
    cap production assets:deploy

    #or all release (can take a lot of time)
    cap production assets:deploy_all
    
    
Result for version 1.0.0:

    /var/www/assets/shared/assets/1.0.0/images/bg.png
    /var/www/assets/shared/assets/1.0.0/javascripts/application.js
    /var/www/assets/shared/assets/1.0.0/styleshets/application.css
    ...
    
    http://cdn.assets.example.com/assets/1.0.0/images/bg.png
    http://cdn.assets.example.com/assets/1.0.0/javascripts/application.js
    http://cdn.assets.example.com/assets/1.0.0/styleshets/application.css
    ...
    
    
    