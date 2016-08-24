require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'
require 'mina_sidekiq/tasks'
require 'mina/scp'
require 'mina/newrelic'
require 'dotenv'
Dotenv.load

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, ENV['DEPLOY_DOMAIN']
set :deploy_to, ENV['DEPLOY_TO']
set :repository, ENV['DEPLOY_REPOSITORY']
set :branch, ENV['DEPLOY_BRANCH']

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['log', '.env']

# Optional settings:
set :user, ENV['DEPLOY_USER']    # Username in the server to SSH to.
set :port, ENV['DEPLOY_PORT']     # SSH port number.
set :forward_agent, true     # SSH forward_agent.

set :use_rbenv, ENV['DEPLOY_USE_RBENV'] == 'true'

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load' if use_rbenv

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/sockets"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/pids"]
end

task :restart => :environment do
  queue %[sudo service puma-manager restart]
  queue %[sudo service workers restart]
end

namespace :config do
  desc "Upload .env config"
  task upload: :environment do
    scp_upload '.env', "#{deploy_to}/#{shared_path}/.env"
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'sidekiq:quiet' unless ENV['DEPLOY_USE_UPSTART']
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      if ENV['DEPLOY_USE_UPSTART']
        invoke :'restart'
      else
        invoke :'puma:phased_restart'
        invoke :'sidekiq:restart'
      end
      invoke :'newrelic:notice_deployment'
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

