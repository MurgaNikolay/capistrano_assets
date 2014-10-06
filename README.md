

deploy.rb

    #Set git tag for assets version
    #Public folder for assets, for example
    set :assets_symlink, '/var/www/assets/public/assets'
    set :assets_build_dir, 'tmp/build' #grunt assets build or assets folder
    #command fo build assets
    set :assets_build_commands, [
      'npm install',
      'bundle exec grunt'
    ]
    
stages/production.rb

    server 'assets.example.com', user: 'deploy', roles: %w{assets}
    
    #deploy some version (version will be requested)
    cap production assets:deploy

    #or all release (can take a lot of time)
    cap production assets:deploy_all
    
    