"""
  
  Name:         server.py
  Author:       Aaron Ortbals
  Description:  Using Flask, provide a simple server and interface to sw_checkin_email.py

"""

from flask import Flask, render_template
app = Flask(__name__)
app.debug = True

# ========================================================================

import re
import sys
import time as time_module
import datetime
import sched
import string
import cookielib
import urllib
import urllib2
import urlparse
import httplib
import smtplib
import getpass
from bs4 import BeautifulSoup
from bs4 import Tag

try:
  from email.mime.multipart import MIMEMultipart
  from email.mime.text import MIMEText
except:
  from email.MIMEMultipart import MIMEMultipart
  from email.MIMEText import MIMEText

from datetime import datetime,date,timedelta,time
from pytz import timezone,utc

import codecs

# ========================================================================

from sw_checkin_email_test import Flight, FlightLeg, FlightLegLocation, \
Reservation, ReadUrl, PostUrl, FindAllByTagClass, FindByTagClass, \
FindNextSiblingByTagClass, HtmlFormParser, ReservationInfoParser, \
getFlightTimes, getBoardingPass, DateTimeToString, getFlightInfo, \
displayFlightInfo, TryCheckinFlight, send_email, RETRY_INTERVAL, \
CHECKIN_WINDOW, base_url, checkin_url, retrieve_url, \
debug_html_files, verbose, dlog, opener, \
airport_timezone_map

# Common US time zones
tz_alaska = timezone('US/Alaska')
tz_aleutian = timezone('US/Aleutian')
tz_arizona = timezone('US/Arizona')
tz_central = timezone('US/Central')
tz_east_indiana = timezone('US/East-Indiana')
tz_eastern = timezone('US/Eastern')
tz_hawaii = timezone('US/Hawaii')
tz_indiana_starke = timezone('US/Indiana-Starke')
tz_michigan = timezone('US/Michigan')
tz_mountain = timezone('US/Mountain')
tz_pacific = timezone('US/Pacific')

@app.route('/')
def index():
  return render_template('index.html')

@app.route('/checkin', methods=['POST', 'GET'])
def checkin():
    error = None
    if request.method == 'POST':
        if True:
          pass
        else:
            error = 'Invalid username/password'
    # the code below this is executed if the request method
    # was GET or the credentials were invalid
    return render_template('status.html', error=error)

@app.route('/search')
def search():
  pass

if __name__ == '__main__':
  app.run()