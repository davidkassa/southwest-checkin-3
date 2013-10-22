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
from functools import wraps

app = Flask(__name__)
app.debug = True

# ========================================================================

import re
import sys
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

from sw_checkin_email import *

app.create_jinja_environment()
app.jinja_env.globals["GOOGLE_ANALYTICS"] = config["GOOGLE_ANALYTICS"]

if not config['CELERY']: scheduleAllExistingReservations()

def is_admin():
  auth = request.authorization
  if not auth or not (auth.username == config["ADMIN_USERNAME"] and auth.password == config["ADMIN_PASSWORD"]):
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
    query = TextField('Confirmation Number', [validators.Required(message='you didn\'t enter a confirmation number')])

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
      return redirect(url_for('flight_status', code=res.code))

    res = db.addReservation(form.firstname.data, form.lastname.data, form.code.data, form.email.data)
    if config["SEND_ADMIN_EMAIL"]:
      admin_message = "First: %s\nLast: %s\nEmail: %s\nConfirmation Number: %s\nTime: %s" % (
        form.firstname.data, form.lastname.data, form.email.data, form.code.data, datetime.now())
      send_email('An automatic southwest check in has been initiated', admin_message, boarding_pass=None, email=config["ADMIN_EMAIL"])
    print 'Created', res
    if not res.active:
      return message('It looks like all of your flights have already taken off :(')

    success = getFlightTimes(res)
    if success:
      message = getFlightInfo(res, res.flights)
      if config["SEND_EMAIL"]:
        send_email('Waiting for SW flight', message, boarding_pass=None, email=res.email);

      scheduleAllFlights(res)
      print 'Current time: %s' % DateTimeToString(datetime.now(utc))

      return redirect(url_for('flight_status', code=res.code))
    else:
      db.isReservationActive(res)
      if not res.active:
        db.deleteReservation(res)
        return display_message("We can't find that reservation!")

  return render_template('index.html', form=form)

@app.route('/search', methods=['GET', 'POST'])
def search():
  if request.method == 'GET':
    return render_template('search.html', form=SearchForm())
  if request.method == 'POST':
    form = SearchForm(request.form)
    if form.validate():
      # reservations = db.findReservationByLastName(form.query.data)
      # if reservations != None:
      #   return redirect(url_for("user_status", last_name=form.query.data))
      return redirect(url_for("flight_status", code=form.query.data))
    return render_template('search.html', form=form)

@app.route('/flights/<code>', methods=['GET'])
def flight_status(code):
  try:
    res = db.findReservation(code)
  except:
    return display_message("We can't find that reservation!")
  return render_template('status.html', res=res, flights=res.flights)

@app.route('/delete/<code>', methods=['POST'])
def flight_delete(code):
  res = db.findReservation(code)
  if res != None:
    mes = "%s will no longer be checked in." % res.code
    db.deleteReservation(res)
    return display_message(mes)
  return abort(400)

# @app.route('/users/<last_name>', methods=['GET'])
# def user_status(last_name):
#   reservations = db.findReservationByLastName(last_name)
#   if reservations != None:
#     return render_template('user.html', reservations=reservations, count=count)
#   return display_message("We can't find that last name!")

@app.route('/message')
def display_message(message):
  return render_template('message.html', message=message)

@app.route('/all')
@requires_authentication
def all_reservations():
  reservations = db.getAllReservations(active=False)
  if reservations != None:
    import threading
    count = threading.activeCount()
    return render_template('all_reservations.html', reservations=reservations, count=count)
  return abort(500)

@app.route('/all/schedule_all', methods=['GET'])
@requires_authentication
def schedule_all_reservations():
  scheduleAllExistingReservations()
  return redirect(url_for("all_reservations"))

@app.route('/all/schedule/<id>', methods=['GET'])
def schedule_flight(id):
  flight = db.Session.query(Flight).get(id)
  result = scheduleFlight(flight.reservation, flight)
  app.logger.debug('Result from scheduling: %s', result)
  return redirect(url_for("all_reservations"))

if __name__ == '__main__':
  # Bind to PORT if defined, otherwise default to 5000.
  port = int(os.environ.get('PORT', 5000))
  app.run(host='0.0.0.0', port=port)
