# Southwest Checkin #

Southwest Checkin automatically checks a passenger into their flights for a given confirmation number. The user will receive an email on successful check in. It contains both a command line interface (CLI) and a web interface. A live, usable version is hosted on Heroku:

[Southwest Checkin on Heroku](http://southwest-checkin.herokuapp.com/)

Here are some of the features of the application:

* Checks the passenger in for all flights (departure and arrival) exactly 24 hours before the flight leaves
* Informs the user via email after successful check in and includes boarding position and boarding pass
* Checks in all passengers for that reservation
* Stores the information in a database in case the web interface or CLI is restarted
* Note: Does *not* work for AirTrans flights

If southwest changes the checkin process, the parser might need to be updated. If you see a bug, file an issue or fork and create a pull request with the fix.


## Installation ##

The easiest way to install the dependencies is with [pip](http://pypi.python.org/pypi/pip), a python package manager. It is also good practice to isolate your environment with a [virtual environment](http://www.virtualenv.org/en/latest/). If you are unfamiliar with pip or virtualenv, I would recommend reading _[Python Ecosystem: An Introduction](http://mirnazim.org/writings/python-ecosystem-introduction/)_.

    $ pip install -r requirements.txt

For the web interface, the [Celery](http://docs.celeryproject.org/en/latest/index.html) task queue is required. [Redis](http://redis.io/) is used as the broker for queuing tasks (although you can setup a different broker such as RabbitMQ). Make sure to set `CELERY=true` to run the web interface.

You will also need to set the appropriate settings for the application. By default, the app will use any environment variables you have set, and fallback to `default_settings.py` for any environment variables that are not set.

For example, in a bash shell I might configure email:

    export CELERY="True"
    export SEND_EMAIL="True"
    export EMAIL_FROM="my@email.com"
    export SEND_ADMIN_EMAIL="True"
    export ADMIN_EMAIL=$EMAIL_FROM
    export SMTP_USER=$EMAIL_FROM
    export SMTP_PASSWORD='mypassword'


These settings will be used in the application. `default_settings.py` will be used for the rest of the configuration like the database, SMTP email port, and debug settings. Override these appropriately. This style of configuration makes it easy to keep sensitive configuration seperate from the public repository and also makes it easy to deploy these settings to Heroku.
Note: If you use Gmail's two factor authentication, you will need a Application Specific password, not your normal password.


### Installation on Ubuntu 12.04 LTS ###

Installation on Ubuntu requires the appropriate system packages.

    $ sudo apt-get install python-dev build-essential python-pip
    $ sudo apt-get install libxml2-dev libxslt-dev libpq-dev


## Web interface usage ##

Enter a first and last name, confirmation number, and email. The system will attempt to locate your reservation and add it to the system for automatic checkin. You will receive an email when you add your reservation to the system and again on successful checkins for your flights. Under a normal round trip scenario, you will be checked in for departure and arrival.

To cancel the automatic checkin, simply [search](http://southwest-checkin.herokuapp.com/search) for the reservation and cancel it.

To run the development server on `localhost:5000`, start Postgres if you are using it. Then:

    $ redis-server # start redis
    $ foreman start -f Procfile.dev


## CLI Usage ##

You can kick off an automatic checkin with the following command. Run the script:

    $ python sw_checkin_email.py John Doe ABC123

Storing the reservations in a database is optional (on by default). If an active reservation is contained in the database, you can resume the automatic checkin by running the following command. It will prompt to ask if you would like to resume any of the previously added reservations.

    $ python sw_checkin_email.py

There are also several useful ways to run the script in the background.

Run the script in the background:

    $ python sw_checkin_email.py John Doe ABC123 &

Run the script in the background and log to file:

    $ python sw_checkin_email.py John Doe ABC123 > sw_checkin_email.log 2>&1 &

Run the script in the background, log to file, and allow yourself to logout (you cannot retake ownership of this command and must use `kill` to stop it)

    $ nohup python sw_checkin_email.py John Doe ABC123 &> sw_checkin_email.log

For more explanation on these commands, you may want to read about [nohup and disown](http://www.basicallytech.com/blog/index.php?/archives/70-Shell-stuff-job-control-and-screen.html#bash_disown).


## Technical Details ##

- The application was written in [Python](http://www.python.org/)
- [Beautiful Soup 4](http://www.crummy.com/software/BeautifulSoup/) scrapes southwest.com
- The web interface was written using [Flask](http://flask.pocoo.org/)
- The database layer was written using [SQLAlchemy](http://www.sqlalchemy.org/)
- [Celery](http://docs.celeryproject.org/en/latest/index.html) and [Redis](http://redis.io/) are used to queue delayed check in tasks for the web interface
- The [live app](http://southwest-checkin.herokuapp.com/) is hosted on a [Heroku](http://www.heroku.com/) free dyno and uses [Heroku Postgres Dev](https://addons.heroku.com/heroku-postgresql) to host the database and [New Relic](https://addons.heroku.com/newrelic) for app statistics

## Known Issues ##

- For AirTrans flights, the application will read the reservation correctly, but checkin attempts will fail.  The application will retry based on the environment settings.

