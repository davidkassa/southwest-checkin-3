"""
  
  Name:         server.py
  Author:       Aaron Ortbals
  Description:  Using Flask, provide a simple server and interface to sw_checkin_email.py

"""

import os
from flask import Flask, render_template, request, redirect, url_for, abort
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
from threading import Timer
import codecs

# ========================================================================

from sw_checkin_email import (Flight, FlightLeg, FlightLegLocation,
Reservation, ReadUrl, PostUrl, FindAllByTagClass, FindByTagClass,
FindNextSiblingByTagClass, HtmlFormParser, ReservationInfoParser,
getFlightTimes, getBoardingPass, DateTimeToString, getFlightInfo,
displayFlightInfo, TryCheckinFlight, send_email, RETRY_INTERVAL,
CHECKIN_WINDOW, base_url, checkin_url, retrieve_url, debug_html_files,
verbose, dlog, opener, airport_timezone_map, should_send_email)

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

# ========================================================================

from wtforms import Form, BooleanField, TextField, PasswordField, validators

class CheckinForm(Form):
    code = TextField('Confirmation Number', [
      validators.Length(min=6, max=6),
      validators.Required()])
    firstname = TextField('First Name', [validators.Required()])
    lastname = TextField('Last Name', [validators.Required()])
    email = TextField('Email', [validators.Required()])

class SearchForm(Form):
    code = TextField('Confirmation Number', [
      validators.Length(min=6, max=6),
      validators.Required()])

# ========================================================================

# Our temporary reservation data store object
reservations = {}

# ========================================================================

@app.route('/')
def index():
  return render_template('index.html', form=CheckinForm())

@app.route('/checkin', methods=['POST'])
def checkin():
  form = CheckinForm(request.form)
  if request.method == 'POST' and form.validate():
    res = Reservation(form.firstname.data, form.lastname.data, form.code.data, form.email.data)
    reservations[form.code.data] = res
    getFlightTimes(res)

    # Log info to console
    message = getFlightInfo(res, res.flights)
    if should_send_email:
      send_email('Waiting for SW flight', message, boarding_pass=None, email=res.email);

    # Schedule all of the flights for checkin.  Schedule 3 minutes before our clock
    # says we are good to go
    for flight in res.flights:
      flight_time = time_module.mktime(flight.legs[0].depart.dt_utc.utctimetuple()) - time_module.timezone
      if flight_time < time_module.time():
        print 'Flight already left!'
      else:
        flight.sched_time = flight_time - CHECKIN_WINDOW - 24*60*60
        flight.sched_time_formatted = DateTimeToString(datetime.fromtimestamp(flight.sched_time, utc))
        flight.seconds = flight.sched_time - time_module.time()
        flight.sched_time_local_formatted = DateTimeToString(flight.legs[0].depart.dt - timedelta(seconds=CHECKIN_WINDOW))
        print 'Update Sched (UTC): %s' % flight.sched_time_formatted
        print 'Update Sched (local): %s' % flight.sched_time_local_formatted     
        print 'Seconds till we try and checkin %s' % flight.seconds

        Timer(flight.seconds, TryCheckinFlight, (res, flight, None, 1)).start()
        # DEBUG
        # if flight == res.flights[0]:
        #   Timer(5, TryCheckinFlight, (res, flight, None, 1)).start()
    
    print 'Current time: %s' % DateTimeToString(datetime.now(utc))
    print 'Flights scheduled.  Waiting...'
    # sch.run()

    return status(res.code)
  return render_template('index.html', form=form)

@app.route('/search', methods=['GET', 'POST'])
def search():
  if request.method == 'GET':
    return render_template('search.html', form=CheckinForm())
  if request.method == 'POST':
    form = SearchForm(request.form)
    if form.validate():
      try:
        res = reservations[form.code.data]
      except:
        return 
      return render_template('status.html', res=res, flights=res.flights)
    return render_template('search.html', form=form)

@app.route('/status')
def status(code):
  try:
    res = reservations[code]
  except:
    return abort(404)
  return render_template('status.html', res=res, flights=res.flights)

if __name__ == '__main__':
  # Bind to PORT if defined, otherwise default to 5000.
  port = int(os.environ.get('PORT', 5000))
  app.run(host='0.0.0.0', port=port)
