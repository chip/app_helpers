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
            file.write "#{environment}:
  <<: *login
  database: #{database}_#{environment}
  
"
          end
        end
      end
    end
    
    desc 'Removes database.yml'
    task :remove do
      `rm config/database.yml`
    end
  end
end