# Southwest Checkin 2.0

[![Build Status](https://travis-ci.org/aortbals/southwest-checkin.svg?branch=master)](https://travis-ci.org/aortbals/southwest-checkin) [![Coverage Status](https://coveralls.io/repos/aortbals/southwest-checkin/badge.svg?branch=master&service=github)](https://coveralls.io/github/aortbals/southwest-checkin?branch=master)

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


## Local Installation

1. While not strictly required, it is recommended to install [`rbenv`](https://github.com/sstephenson/rbenv) and [`ruby-build`](https://github.com/sstephenson/ruby-build) to manage ruby versions in development. Ruby 2.2 or greater is required.

2. Required dependencies

    - Ruby 2.2 or greater
    - Postgres
    - Redis

3. After installing the aforementioned dependencies, install the ruby dependencies:

    ```shell
    bundle install
    ```

4. Create and seed the database:

    ```shell
    rake db:create db:migrate db:seed
    ```

5. Adding some basic test data for development:

    ```shell
    rake dev:prime
    ```

6. Copy `.env.example` to `.env`. The defaults should work in development.

    ```shell
    cp .env.example .env
    ```
7. Run the tests:

    ```shell
    rspec
    ```

8. Run the development server:

    ```
    rails s
    ```

9. Run sidekiq to process jobs:

    ```
    bundle exec sidekiq
    ```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Write rspec tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Debian 7 x64 Installation

Install curl and wget

```
apt-get install -y curl wget
```

Install Postgres apt

```
echo 'deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
wget https://www.postgresql.org/media/keys/ACCC4CF8.asc
apt-key add ACCC4CF8.asc
```

Install nodejs apt
```
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get update
apt-get install -y git nano unzip postgresql postgresql-contrib postgresql-server-dev-9.5 redis-server nodejs tmux
```
Install rvm (run these individually)
```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
rvm install ruby-2.2.3
rvm use 2.2.3
gem install bundler
```
Grab the source for checkin
```
git clone https://github.com/aortbals/southwest-checkin.git
cd southwest-checkin
```
Install the bundled gems
```
bundle install
```
Create a db user and give them create privileges
````
sudo -u postgres createuser root
sudo -u postgres psql -c 'ALTER USER root CREATEDB'
# this fixes db encoding
sed -i -e 's/*default/*default\n  template: template0/g' config/database.yml
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
Set a basic site password
```
sed -i -e 's/protected/protected\n  http_basic_authenticate_with name: "user", password: "password"' app/controllers/application_controller.rb
```
Delete last two lines in config/database.yml that define and pass for production
```
nano config/database.yml
rake db:create db:migrate db:seed
```
Populate the db
```
rake db:create db:migrate db:seed
```
Create a script to launch everything on boot
```
echo '#!/bin/sh
service postgresql restart
service redis-server restart
sleep 2
echo Starting rails
tmux new -s rails  -d
tmux send-keys  -t rails "cd /root/southwest-checkin/app" C-m
tmux send-keys  -t rails "rails s -b 0.0.0.0 -p 80 -e production" C-m
tmux new -s sidekiq -d
sleep 2
echo Starting sidekiq
tmux send-keys  -t sidekiq "cd /root/southwest-checkin" C-m
tmux send-keys  -t sidekiq "bundle exec sidekiq &"" C-m' > /root/start.sh
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
Disable apache
```
update-rc.d apache2 disable
```
Disable ipv6 (causes issues with the mailer)
```
echo 'net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
```
Reboot
```
reboot
```
Generate two secret keys
```
rake secret
rake secret
```
Add these to your config
```
echo 'DEVISE_SECRET_KEY=MYRANDOMSTRING'>> /root/southwest-checkin/.env
echo 'SECRET_KEY_BASE=MYOTHERRANDOMSTRING'>> /root/southwest-checkin/.env
```
Reboot
```
reboot
```
