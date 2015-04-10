Southwest Checkin 2.0

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
