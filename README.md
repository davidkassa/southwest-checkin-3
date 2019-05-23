# Southwest Checkin 2.X

Deploys to Heroku, Rails 5

---

Automatically checks in passengers for their Southwest Flight.

Version 2.0 of this project is a complete rewrite of the service. The brittle HTML parsing and form submissions are a thing of the past. A much better approach is being taken to automate checkins. And, importantly, the new version has a robust test suite. It is even written in a new language (Ruby) and framework (Rails).

If you are interested in the old version, see the [1.0 branch](https://github.com/aortbals/southwest-checkin/tree/1.0).

## Features

- Accounts
  - an easy and convient way to manage your reservations
  - view or remove your reservations at any time
  - increased security
- Email Notifications
  - Notified when a reservation is added
  - Notified on successful checkin
- Checks in all passengers for a given confirmation number
- Secured via HTTPS
- Modern UI
- Modern background processing and job scheduling
- Full test suite

## Debian 7 x64 Installation

Install curl and wget

```
apt-get install -y curl wget
```

Install Postgres repo to apt

```
echo 'deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
wget https://www.postgresql.org/media/keys/ACCC4CF8.asc
apt-key add ACCC4CF8.asc
```

Install stuff

```
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get update
apt-get install -y nodejs git git-core nano unzip postgresql postgresql-contrib postgresql-server-dev-9.5 redis-server tmux autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
```

rbenv doesn't provide any installer, so we have to get use the source from Github. So, we need to clone it in our home directory.
Then add to PATH

```
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
```

** Restart your shell **
Now we need to install Ruby 2.2.1

```
apt-get install build-essential libssl-dev libcurl4-openssl-dev libreadline-dev -y
rbenv install 2.2.1 -k
rbenv global 2.2.1
gem install rails --version 4.2.10
gem install bundler
```

Grab the source for checkin

```
git clone https://github.com/flyize/southwest-checkin.git
cd southwest-checkin
```

Install the bundled gems

```
bundle install
```

Create a db user and give them create privileges (ignore any directory errors)

```
sudo -u postgres createuser root
sudo -u postgres psql -c 'ALTER USER root CREATEDB'
# this fixes db encoding
sed -i -e 's/*default/*default\n  template: template0/g' config/database.yml
```

Populate the db

```
rake db:create db:migrate db:seed
```

Create a config file replace your website, email, and email server. It must accept mail on port 587 with tls.

```
echo 'SITE_NAME=Southwest Checkin
SITE_URL=http://mywebsite.com
ASSET_HOST=http://mywebsite.com
MAILER_DEFAULT_FROM_EMAIL=email@mywebsite.com
MAILER_DEFAULT_REPLY_TO=email@mywebsite.com
DEPLOY_BRANCH=master
DEPLOY_USER=deploy
DEPLOY_PORT=22
MAILER_ADDRESS=mail.mywebsite.com
MAILER_DOMAIN=mywebsite.com
MAILER_USERNAME=email@mywebsite.com
MAILER_PASSWORD=mypassword
MAILER_DEFAULT_HOST=
DEPLOY_DOMAIN=
DEPLOY_TO=
DEPLOY_REPOSITORY=
DEPLOY_USE_RBENV=true
MAILER_DEFAULT_PROTOCOL=http
MAILER_DEFAULT_HOST=mywebsite.com' > .env
```

Create a script to launch everything

```
echo '#!/bin/sh
service postgresql restart
service redis-server restart
sleep 2
echo Starting rails
tmux new -s rails  -d
tmux send-keys  -t rails "cd /root/southwest-checkin/app" C-m
tmux send-keys  -t rails "/root/.rbenv/shims/rails s -b 0.0.0.0 -p 80 -e development" C-m
tmux new -s sidekiq -d
sleep 2
echo Starting sidekiq
tmux send-keys  -t sidekiq "cd /root/southwest-checkin" C-m
tmux send-keys  -t sidekiq "/root/.rbenv/shims/bundle exec sidekiq &" C-m' > /root/start.sh
```

Make it executable

```
chmod +x /root/start.sh
```

Make the script run on boot

```
sed -i -e 's|"exit 0"|removed|g' /etc/rc.local
sed -i -e 's|exit 0|/root/start.sh\nexit 0|g' /etc/rc.local
```

Disable apache (if apache is installed)

```
update-rc.d apache2 disable
```

Disable ipv6 (otherwise you will find issues with the mailer)

```
echo 'net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
```

Enable Email in Dev Mode (update action_mailer settings)
nano config/environments/development.rb

```
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.asset_host = ENV['ASSET_HOST']
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = {
    host: ENV['MAILER_DEFAULT_HOST'],
    protocol: ENV['MAILER_DEFAULT_PROTOCOL'] || 'https'
  }
  config.action_mailer.default_options  = {
    from: ENV['MAILER_DEFAULT_FROM_EMAIL'],
    reply_to: ENV['MAILER_DEFAULT_REPLY_TO']
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV['MAILER_ADDRESS'],
    user_name:            ENV['MAILER_USERNAME'],
    password:             ENV['MAILER_PASSWORD'],
    port:                 587,
    authentication:       'plain',
    enable_starttls_auto: true }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
```

Reboot

```
reboot
```
