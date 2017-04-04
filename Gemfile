ruby '2.2.1'
source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
gem "autoprefixer-rails"
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'typhoeus', '~> 0.7' # HTTP request client

gem 'devise', '~> 3.4' # Authentication

gem 'sidekiq', '~> 3.5' # Background job processing queue
gem 'sinatra', :require => nil # Required for sidekiq web UI
gem 'sidekiq-failures' # Track sidekiq failures

gem 'roadie-rails' # Inline styles for emails

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Puma as the app server
gem 'puma'

# Use Mina for deployment
gem 'mina'
gem 'mina-puma', :require => false
gem 'mina-sidekiq', :require => false
gem 'mina-scp', :require => false
gem 'mina-newrelic', :require => false

gem 'dotenv-rails'

# Skylight for performance monitoring
gem 'skylight'

# New Relic application monitoring
gem 'newrelic_rpm'

# Pagination
gem 'kaminari'

# syslog logging with lograge
# gem 'syslogger', '~> 1.6.0'
# gem 'lograge', '~> 0.3.1'

group :development, :test do
  gem 'rspec-rails', '~> 3.0'
  gem 'awesome_print'
  gem 'vcr', '~> 2.9'

  gem 'letter_opener'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'webmock'
  gem 'shoulda-matchers', require: false
  gem 'timecop'
  gem 'coveralls', require: false
  gem 'json-schema-rspec'
end

group :developement do
  gem 'guard'
  gem 'guard-rspec'
end
