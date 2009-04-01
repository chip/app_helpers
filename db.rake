namespace :db do
  task :config => 'app_helpers:db:config'
end

namespace :app_helpers do
  
  desc 'Runs db:config and creates database'
  task :db => [ 'app_helpers:db:config', 'db:create' ]
  
  namespace :db do
    desc 'Creates a generic database.yml file'
    task :config do
      if ENV['quiet'] != 'true'
        if ENV['db']
          database = ENV['db']
        else
          puts('Database name?')
          database = STDIN.gets.strip
        end
        File.open 'config/database.yml', 'w' do |file|
          file.write "login: &login
  adapter:  mysql
  encoding: utf8
  username: deploy
  password: 
  host: localhost
  socket:  <%= ['/opt/local/var/run/mysql5/mysqld.sock',
                '/opt/local/var/run/mysqld/mysqld.sock',
                '/var/run/mysqld/mysqld.sock',
                '/tmp/mysql.sock'].select { |f| File.exist? f }.first %>
"                    
          ['development', 'test', 'staging', 'production'].each do |environment|  
            current_database = environment == 'production' ? "#{database}" : "#{database}_#{environment}"
            file.write "#{environment}:
  <<: *login
  database: #{current_database}
  
"
          end
        end
      end
    end
    
    desc 'Sets database permissions'
    task :perms do
      puts "Fetching Database config for RAILS_ENV=#{RAILS_ENV} (default environment is 'development' if blank)\n\n"
      
      config = Rails::Configuration.new
      database = ENV['RAILS_ENV'].blank? ? 
        config.database_configuration["development"] : config.database_configuration["#{ENV['RAILS_ENV']}"]
      # Without Rails, we can do
      # 
      # file_handle = YAML.load(File.new(”path/to/database.yml”)
      # hashes = file_handle.each {|value| value.inspect}
      # (Now you have access to hashes[”production”])

      mysql_user = ask_me("Login to MySQL as? (default: root)", 'root')
      mysql_password = ask_me("Password for Mysql login? (default from database.yml: #{database['password']})", '')
      grant_user = ask_me("Username to use for GRANT privileges? (default: deploy)", 'deploy')
      grant_password = ask_me("Password to use for GRANT privileges? (default: )", '')
       
      my_command("mysql -e \"GRANT ALL ON #{database['database']}.* TO '#{grant_user}'@'localhost' IDENTIFIED BY '#{grant_password}'")
      my_command("mysql -e \"FLUSH PRIVILEGES\"")

    end
    
    desc 'Removes database.yml'
    task :remove do
      `rm config/database.yml`
    end
  end
end

def my_command(command)
  puts "Executing command...\n#{command}"
  %x( command )
end

def ask_me(question, default = '')
  puts "#{question}"
  response = STDIN.gets.strip
  response.blank? ? default : response
end