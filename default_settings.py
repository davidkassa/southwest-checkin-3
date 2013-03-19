# -*- coding: utf-8 -*-

STORE_DATABASE = False # Store all data in a heroku/pgres/sqlite database? Otherwise, use memory
HEROKU = False # Use heroku postgres?
POSTGRES = '' # i.e. 'postgresql://postgres:password@localhost/southwest-checkin'
SQLITE = '' # i.e. 'southwest-checkin.db'
RETRY_INTERVAL = 5 # If we are unable to check in, how soon should we retry?
CHECKIN_WINDOW = 60 # How soon before the designated time should we try to check in?
SEND_EMAIL = False # Send email to the users?
EMAIL_FROM = None
EMAIL_TO = None # configure to address if using as a script
ADMIN_USERNAME = 'admin'
ADMIN_PASSWORD = 'secret'
SEND_ADMIN_EMAIL = False
ADMIN_EMAIL = ''
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SMTP_AUTH = True
SMTP_USER = EMAIL_FROM
SMTP_PASSWORD = ''
SMTP_USE_TLS = True
DEBUG_HTML_FILES = False # Save html data from accessed web pages for debugging purposes
VERBOSE = False # Log debug messages to console