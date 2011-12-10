Capistrano::Configuration.instance(:must_exist).load do
  
  default_run_options[:pty] = true
  
  ## Define the default roles
  role :app
  
  ## Set the default configuration
  set :user, "deploy"
  set :ssh_options, {:forward_agent => true, :port => 22}
  set :environment, "production"
  set :branch, "master"
  
  namespace :setup do
  
    desc 'Initialises the application on your server(s)'
    task :default do
      
      unless ENV['DBPASS']
        puts "\n    \e[31mAn error occurred while setting up your remote repository:\n\n"
        puts "    You must pass DBPASS to this task. This should be the database password for the database"
        puts "    with the name '#{database_user}' on #{database_host}.\e[0m\n\n"
        
        next
      end
    
      ## Clear anything out the way of the application
      run "rm -Rf #{deploy_to}"
    
      ## Clone the repository into the folder
      run "git clone -n #{repository} #{deploy_to} --branch #{branch} --quiet"

      ## Create a rollback branch, create a new branch called 'deploy' and remove the 
      ## origin branch
      run "cd #{deploy_to} && git branch rollback && git checkout -b deploy && git branch -d #{branch}"
    
      ## Upload the database configuration
      add_db_config
      
      ## Finalize
      deploy.finalise
    end
    
    desc 'Initialises the application (including the database schema)'
    task :full do
      puts
      puts "    \e[36mPotentially dangerous action - read this carefully:\e[0m"
      puts "    This task will clear your database (#{database_name}) when it has completed setting"
      puts "    up the remote repository. We will wait 15 seconds for you to change your mind. Press"
      puts "    CTRL+C to cancel this task now."
      puts
      sleep 15
      
      default
      load_schema
      deploy.start
      
      puts
      puts "    \e[32mYour application has now been set up for the first time\e[0m"
      puts
    end

    desc 'Upload a database configuration using the variables you enter'
    task :add_db_config, :roles => [:app] do
      next unless fetch(:database_host, nil)
      configuration = Array.new.tap do |a|
        a << "#{environment}:"
        a << "  adapter: mysql2"
        a << "  encoding: utf8"
        a << "  reconnect: true"
        a << "  host: #{database_host}"
        a << "  database: #{database_name}"
        a << "  username: #{database_user}"
        a << "  password: #{ENV['DBPASS'] || 'xxxxx'}"
        a << "  pool: 5\n"
      end.join("\n")
      put configuration, "#{deploy_to}/config/database.yml"
    end
    
    desc 'Load the schema'
    task :load_schema, :roles => [:app], :only => {:database_ops => true} do
      run "cd #{deploy_to} && RAILS_ENV=#{environment} bundle exec rake db:schema:load"
    end
  end
  
  namespace :deploy do
    desc 'Deploy your application'
    task :default do
      update_code
      restart
    end
    
    desc 'Deploy and run migrations'
    task :migrations do
      set :run_migrations, true
      default
    end
    
    
    task :update_code do
      run "cd #{deploy_to} && git branch -d rollback && git branch rollback"
      run "cd #{deploy_to} && git fetch origin && git reset --hard origin/#{fetch(:branch)}"
      finalise
    end
    
    task :finalise do
      execute = Array.new
      execute << "cd #{deploy_to}"
      execute << "git submodule init"
      execute << "git submodule sync"
      execute << "git submodule update --recursive"
      run execute.join(' && ')

      run "cd #{deploy_to} && bundle --deployment --quiet"
      assets
      migrate if fetch(:run_migrations, false)
    end
    
    desc 'Run any database migrations'
    task :migrate, :roles => [:app], :only => {:database_ops => true} do
      run "cd #{deploy_to} && RAILS_ENV=#{environment} bundle exec rake db:migrate"
    end
    
    task :assets, :roles => [:app] do
      run "if [ -e #{deploy_to}/app/assets ] ; then cd #{deploy_to} && RAILS_ENV=#{environment} bundle exec rake assets:precompile ; fi"
    end
    
    desc 'Reset the application'
    task :restart, :roles => [:app] do
      run "mkdir -p #{deploy_to}/tmp && touch #{deploy_to}/restart.txt"
    end
    
    desc 'Start the application'
    task :start, :roles => [:app] do
      restart
    end
    
    desc 'Stop the application'
    task :stop, :roles => [:app] do
      restart
    end
    
  end
end
