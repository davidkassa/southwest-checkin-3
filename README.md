# [Chkmein.co](https://chkmein.co) - Southwest Checkin 2.0

[Chkmein.co](https://chkmein.co) automatically checks in passengers for their Southwest Flight.

Version 2.0 of this project is a complete rewrite of the service. The brittle HTML parsing and form submissions are a thing of the past. A much better approach is being taken to automate checkins. And, importantly, the new version has a robust test suite. It is even written in a new language (Ruby) and framework (Rails).

If you are interested in the old version, see the 1.0 tag.

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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Write rspec tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
