"""
  
  Name:         server.py
  Author:       Aaron Ortbals
  Description:  Using Flask, provide a simple server and interface to sw_checkin_email.py
  License:

    The MIT License
   
    Copyright (c) 2012 Aaron Ortbals
   
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
   
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
   
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

"""

import os
from flask import Flask, render_template, request, redirect, url_for, abort, Response

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
from datetime import datetime,date,timedelta,time
from pytz import timezone,utc
import codecs
from functools import wraps

try:
  from email.mime.multipart import MIMEMultipart
  from email.mime.text import MIMEText
except:
  from email.MIMEMultipart import MIMEMultipart
  from email.MIMEText import MIMEText

from sw_checkin_email import *


def is_admin():
  auth = request.authorization
  if not auth or not (auth.username == username
                      and auth.password == password):
    return False
  return True

def requires_authentication(func):
  """ function decorator for handling authentication """
  @wraps(func)
  def _auth_decorator(*args, **kwargs):
      """ does the wrapping """
      if not is_admin():
          return Response("Could not authenticate you", 
                          401, 
                          {"WWW-Authenticate":'Basic realm="Login Required"'})
      return func(*args, **kwargs)

  return _auth_decorator

# ========================================================================

from wtforms import Form, BooleanField, TextField, PasswordField, validators

class CheckinForm(Form):
    code = TextField('Confirmation Number', [
      validators.Length(min=6, max=6, message='it must be 6 characters'),
      validators.Required(message='you didn\'t enter a confirmation number')])
    firstname = TextField('First Name', [validators.Required(message='you didn\'t enter your first name')])
    lastname = TextField('Last Name', [validators.Required(message='you didn\'t enter your last name')])
    email = TextField('Email', [validators.Required(message='you didn\'t enter your email address')])

class SearchForm(Form):
    code = TextField('Confirmation Number', [
      validators.Length(min=6, max=6, message='it must be 6 characters'),
      validators.Required(message='you didn\'t enter a confirmation number')])

# ========================================================================

db.create_all()
scheduleAllExistingReservations()

# ========================================================================

@app.route('/')
def index():
  return render_template('index.html', form=CheckinForm())

@app.route('/checkin', methods=['POST'])
def checkin():
  form = CheckinForm(request.form)
  if request.method == 'POST' and form.validate():
    
    res = db.findReservation(form.code.data)
    if res:
      print 'Reservation %s is already in the system...' % res.code
      return status(res.code)

    res = db.addReservation(form.firstname.data, form.lastname.data, form.code.data, form.email.data)
    print 'Created', res
    if not res.active:
      return message('It looks like all of your flights have already taken off :(')
    
    success = getFlightTimes(res)
    if success:
      message = getFlightInfo(res, res.flights)
      if should_send_email:
        send_email('Waiting for SW flight', message, boarding_pass=None, email=res.email);

      scheduleAllFlights(res)
      print 'Current time: %s' % DateTimeToString(datetime.now(utc))

      return status(res.code)
    else:
      db.isReservationActive(res)
      if not res.active:
        db.deleteReservation(res)
        return display_message("We can't find that reservation!")

  return render_template('index.html', form=form)

@app.route('/search', methods=['GET', 'POST'])
def search():
  if request.method == 'GET':
    return render_template('search.html', form=CheckinForm())
  if request.method == 'POST':
    form = SearchForm(request.form)
    if form.validate():
      try:
        res = db.findReservation(form.code.data)
      except:
        return display_message("We can't find that reservation!")
      return render_template('status.html', res=res, flights=res.flights)
    return render_template('search.html', form=form)

@app.route('/status')
def status(code):
  try:
    res = db.findReservation(code)
  except:
    return display_message("We can't find that reservation!")
  return render_template('status.html', res=res, flights=res.flights)

@app.route('/message')
def display_message(message):
  return render_template('message.html', message=message)

@app.route('/all')
@requires_authentication
def all_reservations():
  try:
    reservations = db.getAllReservations()
  except:
    return abort(500)
  return render_template('all_reservations.html', reservations=reservations)

@app.route('/delete/<code>', methods=['GET', 'POST'])
def delete_reservation(code):
  try:
    res = db.findReservation(code)
  except:
    return abort(400)
  mes = "%s will no longer be checked in." % res.code
  db.deleteReservation(res)
  return display_message(mes)

if __name__ == '__main__':
  # Bind to PORT if defined, otherwise default to 5000.
  port = int(os.environ.get('PORT', 5000))
  app.run(host='0.0.0.0', port=port)
