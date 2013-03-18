#!/usr/bin/env python

# The MIT License
#
# Copyright (c) 2008 Joe Beda
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Based on script by Ken Washington
#   http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/496790

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

from models import Reservation, Flight, FlightLeg, FlightLegLocation

# Store all data in a database?
STORE_DATABASE = True
# Heroku Postgres
heroku = False
# SQLite
db_filename = 'southwest-checkin.db'

from db import Database
if STORE_DATABASE:
  if heroku:
    db = Database(heroku=True)
  else:
    db = Database(db_filename)
else:
  db = Database()
db.create_all()

# If we are unable to check in, how soon should we retry?
RETRY_INTERVAL = 5

# How soon before the designated time should we try to check in?
CHECKIN_WINDOW = 60

# Admin
username='admin'
password='secret'

# Email configuration
should_send_email = False
email_from = None
email_to = None

# SMTP server config
if False:  # local config
  smtp_server = 'localhost'
  smtp_port = 25
  smtp_auth = False
  smtp_user = email_from
  smtp_password = ''  # if blank, we will prompt first and send test message       
  smtp_use_tls = False
else:  # gmail config
  smtp_server = 'smtp.gmail.com'
  smtp_port = 587
  smtp_auth = True
  smtp_user = email_from
  smtp_password = ''  # if blank, we will prompt first and send test message
  smtp_use_tls = True

# ========================================================================
# fixed page locations and parameters
base_url = 'http://www.southwest.com'
checkin_url = urlparse.urljoin(base_url, '/flight/retrieveCheckinDoc.html')
retrieve_url = urlparse.urljoin(base_url, '/flight/lookup-air-reservation.html')

# ========================================================================

class Error(Exception):
  pass

# ========================================================================

# Save html data from accessed web pages for debugging purposes
debug_html_files = False

# Log debug messages to console
verbose = False
def dlog(str):
  if verbose:
    print 'DEBUG: %s' % str

# ========================================================================

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

airport_timezone_map = {
  'ABQ': tz_mountain,
  'ALB': tz_eastern,
  'AMA': tz_central,
  'AUS': tz_central,
  'BDL': tz_eastern,
  'BHM': tz_central,
  'BNA': tz_central,
  'BOI': tz_mountain,
  'BUF': tz_eastern,
  'BUR': tz_pacific,
  'BWI': tz_eastern,
  'CLE': tz_eastern,
  'CMH': tz_eastern,
  'CRP': tz_central,
  'DAL': tz_central,
  'DEN': tz_mountain,
  'DTW': tz_eastern,
  'ELP': tz_mountain,
  'FLL': tz_eastern,
  'GEG': tz_pacific,
  'HOU': tz_central,
  'HRL': tz_central,
  'IAD': tz_eastern,
  'IND': tz_eastern,
  'ISP': tz_eastern,
  'JAN': tz_eastern,
  'JAX': tz_eastern,
  'LAS': tz_pacific,
  'LAX': tz_pacific,
  'LBB': tz_central,
  'LIT': tz_central,
  'MAF': tz_central,
  'MCI': tz_central,
  'MCO': tz_eastern,
  'MDW': tz_central,
  'MHT': tz_eastern,
  'MSP': tz_central,
  'MSY': tz_central,
  'OAK': tz_pacific,
  'OKC': tz_central,
  'OMA': tz_central,
  'ONT': tz_pacific,
  'ORF': tz_eastern,
  'PBI': tz_eastern,
  'PDX': tz_pacific,
  'PHL': tz_eastern,
  'PHX': tz_arizona,
  'PIT': tz_eastern,
  'PVD': tz_eastern,
  'RDU': tz_eastern,
  'RNO': tz_pacific,
  'RSW': tz_eastern,
  'SAN': tz_pacific,
  'SAT': tz_central,
  'SDF': tz_eastern,
  'SEA': tz_pacific,
  'SFO': tz_pacific,
  'SJC': tz_pacific,
  'SLC': tz_mountain,
  'SMF': tz_pacific,
  'SMF': tz_pacific,
  'SNA': tz_pacific,
  'STL': tz_central,
  'TPA': tz_eastern,
  'TUL': tz_central,
  'TUS': tz_arizona,
}

# =========== function definitions =======================================

# build our cookie based opener
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor())

# this function reads a URL and returns the text of the page
def ReadUrl(url):
  headers = {}
  headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
  headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8 GTB7.1'

  dlog('GET to %s' % url)
  dlog('  headers: %s' % headers)

  try:
    req = urllib2.Request(url=url, headers=headers)
    resp = opener.open(req)
  except Exception, e:
    raise Error('Cannot GET: %s' % url, e)

  return (resp.read(), resp.geturl())

# this function sends a post just like you clicked on a submit button
def PostUrl(url, params):
  str_params = urllib.urlencode(params, True)
  headers = {}
  headers['Content-Type'] = 'application/x-www-form-urlencoded'
  headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
  headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8 GTB7.1'

  dlog('POST to %s' % url)
  dlog('  data: %s' % str_params)
  dlog('  headers: %s' % headers)

  try:
    req = urllib2.Request(url=url, data=str_params, headers=headers)
    resp = opener.open(req)
  except Exception, e:
    raise Error('Cannot POST: %s' % url, e)

  return (resp.read(), resp.geturl())
  
def FindAllByTagClass(soup, tag, klass):
  return soup.find_all(tag, 
      attrs = { 'class': re.compile(re.escape(klass)) })

def FindByTagClass(soup, tag, klass):
  return soup.find(tag, 
      attrs = { 'class': re.compile(re.escape(klass)) })
      
def FindNextSiblingByTagClass(soup, tag, klass):
  return soup.find_next_sibling(tag, 
      attrs = { 'class': re.compile(re.escape(klass)) })

class HtmlFormParser(object):
  class Input(object):
    def __init__(self, tag):
      self.type = tag.get('type', 'text')
      self.name = tag.get('name', '')
      self.value = tag.get('value', '')
      # default checked to true for hidden and text inputs
      default_checked = not(self.type == 'checkbox' or self.type == 'radio' 
          or self.type == 'submit')
      self.checked = tag.get('checked', default_checked)
      
    def __str__(self):
      return repr(self.__dict__)
      
    def addToParams(self, params):
      if self.checked:
        params.append((self.name, self.value))
      
  def __init__(self, data, page_url, id):
    self.inputs = []
    self.formaction = ''

    soup = BeautifulSoup(data, "lxml")
    # Write to file for debug purposes
    if debug_html_files:
      f = codecs.open('html_data_' + str(datetime.now()) + '.html', encoding='utf-8', mode='w+')
      f.write(str(data))
      f.close

    form = soup.find('form', id=id)
    print
    if form == None:
      print("Couldn't find the HTML form to lookup the flight! Did the web page change? Or are we too early?")
    else:
      self.formaction = form.get('action', None)
      self.submit_url = urlparse.urljoin(page_url, self.formaction)

      # find all inputs
      for i in form.find_all('input'):
        input = HtmlFormParser.Input(i)
        if input.name:
          self.inputs.append(input)
          
  def submit(self):
    """Submit the form and return the (contents, url)."""
    try:
      post = PostUrl(self.submit_url, self.getParams())
    except:
      print 'The form post failed.'
      return None
    return post
          
  def validateSubmitButtons(self):
    """Ensures that one and only one submit is 'checked'."""
    numChecked = 0
    for i in self.inputs:
      if i.type == 'submit' and i.checked:
        numChecked += 1
    if numChecked > 1:
      raise Error('Too many submit buttons checked on form!')
    
    # None checked, default to the first one
    if numChecked == 0:
      for i in self.inputs:
        if i.type == 'submit':
          i.checked = True
          break
  
  def setSubmit(self, name, value=None):
    for i in self.inputs:
      if i.type == 'submit' and i.name == name:
        if value == None or i.value == value:
          i.checked = True
          break
  
  def getParams(self):
    self.validateSubmitButtons()
    params = []
    for i in self.inputs:
      i.addToParams(params)
    return params
    
  def setTextField(self, name, value):
    for i in self.inputs:
      if i.type == 'text' and i.name == name:
        i.value = value
        break
    
  def setAllCheckboxes(self, name):
    for i in self.inputs:
      if i.type == 'checkbox' and i.name == name:
        cb.checked = True
        break

class ReservationInfoParser(object):
  """ This class finds the relevant information for departure and
      returning flights in a reservation.

      Attributes:
        flights = array of Flights
  """

  def __init__(self, data):
    
    soup = BeautifulSoup(data, "lxml")
    self.flights = []
    
    # The table containing departure flights
    airItineraryDepartTable = soup.find_all('table', id="airItinerarydepart")
    # The table containing return flights
    airItineraryReturnTable = soup.find_all('table', id="airItineraryreturn")
    
    dlog("Checking reservation departure flights...")
    if airItineraryDepartTable:
      self.exists = True
      for item in airItineraryDepartTable:
        self.flights.append(self._parseFlightInfo(item))
    else:
      print "Can't find a departure flight... are we sure this reservation exists?"
      self.exists = False
    
    dlog("Checking reservation return flights...")
    if airItineraryReturnTable:
        for item in airItineraryReturnTable:
          self.flights.append(self._parseFlightInfo(item))
    else:
      dlog("You don't have a return flight.")

  def _parseFlightInfo(self, soup):
    """ For each reservation, get the date, and each flight leg with airport code, 
        departure and arrival times
    """
    flight = Flight()

    # Get flight reservation date from first flight leg
    flight_date_str = FindByTagClass(soup, 'span', 'travelDateTime').string.strip()
    day = date(*time_module.strptime(flight_date_str, '%A, %B %d, %Y')[0:3])
    dlog("Reservation Date: " + str(day))

    # Each flight leg is represented in a row in the HTML table.
    # Each row includes arrival and departure times and flight number.
    for tr in soup.find_all("tr", recursive=False):
      flight_leg = FlightLeg()
      flight.legs.append(flight_leg)

      # Get flight number
      parent = FindByTagClass(tr, 'td', 'flightNumber')
      flight_leg.flight_number = parent.strong.contents[0]
      print "Found flight", flight_leg.flight_number

      # List of arrival and departure details for each airport
      flight_leg_soup = soup.find('table', 'airItineraryFlightRouting').find_all('tr')
      dlog("Parsing Departure:")
      flight_leg.depart = self._parseFlightLegDetails(day, flight_leg_soup[0])
      dlog("Parsing Arrival:")
      flight_leg.arrive = self._parseFlightLegDetails(day, flight_leg_soup[1])

      if flight_leg.arrive.dt_utc < flight_leg.depart.dt_utc:
        flight_leg.arrive.dt = flight_leg.arrive.tz.normalize(
          flight_leg.arrive.dt.replace(day = flight_leg.arrive.dt.day+1))
        flight_leg.arrive.dt_utc = flight_leg.arrive.dt.astimezone(utc)
        flight_leg.arrive.dt_formatted = DateTimeToString(flight_leg.arrive.dt)
        flight_leg.arrive.dt_utc_formatted = DateTimeToString(flight_leg.arrive.dt_utc)
 
    return flight

  def _parseFlightLegDetails(self, day, legDetails):
    '''
      Return a FlightLegLocation with parsed leg location information
    '''
    f = FlightLegLocation()
    # Get airport code
    departure_airport = FindByTagClass(legDetails, 'td', 'routingDetailsStops')
    f.airport = re.findall('[A-Z]{3}', str(departure_airport))[0]
    dlog("Airport Code: " + f.airport)
    # Cannot get the find method with regex working
    # f.airport = departure_airport.find(text=re.compile('[A-Z]{3}'))
    
    # Get timezone 
    f.tz = airport_timezone_map[f.airport]
    
    # Get time
    segmentTime = FindByTagClass(legDetails, 'td', 'routingDetailsTimes').strong.span.contents[0]
    # Create time() object
    flight_time = time(*time_module.strptime(segmentTime.strip(), '%I:%M %p')[3:5])
    dlog("Time: " + str(flight_time))
    f.dt = f.tz.localize(
      datetime.combine(day, flight_time), is_dst=None)
    f.dt_utc = f.dt.astimezone(utc)
    # Formatted datetime
    f.dt_utc_formatted = DateTimeToString(f.dt_utc)
    f.dt_formatted = DateTimeToString(f.dt)
    
    return f
    

# this routine extracts the departure date and time
def getFlightTimes(res):
  if res.new:
    (swdata, form_url) = ReadUrl(retrieve_url)

    form = HtmlFormParser(swdata, form_url, 'pnrFriendlyLookup_check_form')

    # load the parameters into the text boxes
    form.setTextField('confirmationNumberFirstName', res.first_name)
    form.setTextField('confirmationNumberLastName', res.last_name)
    form.setTextField('confirmationNumber', res.code)

    # submit the request to pull up the reservations on this confirmation number
    (reservations, _) = form.submit()

    info = ReservationInfoParser(reservations)
    if info.exists:
      res.flights = info.flights
      res.new = False
      db.Session.commit()
      return True
    else:
      return False

def getBoardingPass(res):
  # read the southwest checkin web site
  (swdata, form_url) = ReadUrl(checkin_url)

  # parse the data
  form = HtmlFormParser(swdata, form_url, 'itineraryLookup')
  if not hasattr(form, 'submit_url'): # The form was not created correctly
    return None

  # load the parameters into the text boxes by name
  # where the names are obtained from the parser
  form.setTextField('confirmationNumber', res.code)
  form.setTextField('firstName', res.first_name)
  form.setTextField('lastName', res.last_name)

  # submit the request to pull up the reservations
  dlog("Submitting the form for the checkin page...")
  (reservations, form_url) = form.submit()
    
  # parse the returned reservations page
  dlog("Parsing the checkin options page...\nURL: " + form_url)
  form = HtmlFormParser(reservations, form_url, 'checkinOptions')
  if not hasattr(form, 'submit_url'): # The form was not created correctly
    return None
  
  # Need to check all of the passengers
  for i in form.inputs:
    if i.type == 'checkbox' and i.name.startswith('checkinPassengers'):
      i.checked = True
  
  # This is the button to press
  form.setSubmit('printDocuments')

  # finally, lets check in the flight and make our success file
  (checkinresult, form_url) = form.submit()
  if debug_html_files:
    f = codecs.open('html_checkin_success_' + str(datetime.now()) + '.html', encoding='utf-8', mode='w+')
    f.write(str(checkinresult))
    f.close

  soup = BeautifulSoup(checkinresult, "lxml")
  pos_boxes = FindAllByTagClass(soup, 'div', 'boardingPosition')
  pos = []
  for box in pos_boxes:
    group = None
    group_img = FindByTagClass(box, 'img', 'group')
    if group_img:
      group = group_img['alt']
    num = 0
    for num_img in FindAllByTagClass(box, 'img', 'position'):
      num *= 10
      num += int(num_img['alt'])
    pos.append('%s%d' % (group, num))

  # Add a base tag to the soup
  tag = soup.new_tag('base', href=urlparse.urljoin(form_url, '.'))
  soup.head.insert(0, tag)

  return (', '.join(pos), str(soup))

def DateTimeToString(time):
  return time.strftime('%I:%M%p %b %d %y %Z');


# print some information to the terminal for confirmation purposes
def getFlightInfo(res, flights):
  message = ''
  message += 'Confirmation number: %s\r\n' % res.code
  message += 'Passenger name: %s %s\r\n' % (res.first_name, res.last_name)

  for (i, flight) in enumerate(flights):
    message += 'Flight %d:\n' % (i+1, )
    if flight.success:
      message += '  Flight was successfully checked in at %s\n' % flight.position
    for leg in flight.legs:
      message += '  Flight Number: %s\n    Departs: %s %s (%s)\n    Arrives: %s %s (%s)\n' \
          % (leg.flight_number, leg.depart.airport, leg.depart.dt_formatted,
             leg.depart.dt_utc_formatted,
             leg.arrive.airport, leg.arrive.dt_formatted,
             leg.arrive.dt_utc_formatted)
  return message

def displayFlightInfo(res, flights, do_send_email=False):
  message = getFlightInfo(res, flights)
  print "Flight Info:"
  print message
  if do_send_email:
    send_email('Waiting for SW flight', message);

def TryCheckinFlight(res_id, flight_id, sch, attempt):
  res = db.Session.query(Reservation).filter_by(id=res_id).one()
  flight = db.Session.query(Flight).filter_by(id=flight_id).one()
  print '-='*30
  print 'Trying to checkin flight at %s' % DateTimeToString(datetime.now(utc))
  print 'Attempt #%s' % attempt
  displayFlightInfo(res, [flight])
  try:
    (position, boarding_pass) = getBoardingPass(res)
  except:
    position = None
  if position:
    flight.success = True
    flight.position = position
    message = ''
    message += 'SUCCESS.  Checked in at position %s\r\n' % position
    message += getFlightInfo(res, [flight])
    print message
    db.Session.commit()
    if hasattr(res, 'email'):
      send_email('Flight checked in!', message, boarding_pass, res.email)
    else:
      send_email('Flight checked in!', message, boarding_pass)
  else:
    if attempt > (CHECKIN_WINDOW * 2) / RETRY_INTERVAL:
      print 'FAILURE.  Too many failures, giving up.'
    else:
      print 'FAILURE.  Scheduling another try in %d seconds' % RETRY_INTERVAL
      if (sch): # Traditional scheduler - command line
        sch.enterabs(time_module.time() + RETRY_INTERVAL, 1,
                     TryCheckinFlight, (res.id, flight.id, sch, attempt + 1))
      else: # Async timer - Flask
        t = Timer(RETRY_INTERVAL, TryCheckinFlight, (res.id, flight.id, None, attempt + 1))
        t.daemon = True
        t.start()
      
def send_email(subject, message, boarding_pass=None, email=None):
  if not should_send_email:
    return

  global email_to
  if email != None:
    email_to = email

  for to in [string.strip(s) for s in string.split(email_to, ',')]:
    try:
      smtp = smtplib.SMTP(smtp_server, smtp_port)
      smtp.ehlo()
      if smtp_use_tls:
        smtp.starttls()
      smtp.ehlo()
      if smtp_auth:
        smtp.login(smtp_user, smtp_password)
      print 'Sending mail to %s.' % to
      msg = MIMEMultipart('mixed')
      msg['Subject'] = subject
      msg['To'] = to
      msg['From'] = email_from
      msg.attach(MIMEText(message, 'plain'))
      if boarding_pass:
        msg_bp = MIMEText(boarding_pass, 'html')
        msg_bp.add_header('content-disposition', 'attachment', filename='boarding_pass.html')
        msg.attach(msg_bp)
      smtp.sendmail(email_from, to, msg.as_string())
      
      print 'Email sent successfully.'
      smtp.close()
    except Exception, e:
      print 'Error sending email!'
      print sys.exc_info()[1]
      raise

def scheduleAllFlights(res, blocking=False, scheduler=None):
  """ Schedule all of the flights for checkin.  Schedule 1 minute before our clock
      says we are good to go
  """
  for (i, flight) in enumerate(res.flights):
    flight_time = time_module.mktime(flight.legs[0].depart.dt_utc.utctimetuple()) - time_module.timezone
    dlog("Flight time (s via mktime): %s" % flight_time)
    if flight_time < time_module.time():
      print 'Flight %s already left...' % (i+1)
      flight.active = False
    elif not flight.success:
      seconds_before = CHECKIN_WINDOW + 24*60*60 # how many seconds before the flight time do we check in
      flight.sched_time = flight_time - seconds_before
      flight.sched_time_formatted = DateTimeToString(flight.legs[0].depart.dt_utc.replace(tzinfo=utc) - timedelta(seconds=seconds_before))
      flight.seconds = flight.sched_time - time_module.time()
      # Retrieve timezone and apply it because datetimes are stored as naive (no timezone information)
      tz = airport_timezone_map[flight.legs[0].depart.airport]
      flight.sched_time_local_formatted = DateTimeToString(flight.legs[0].depart.dt_utc.replace(tzinfo=utc).astimezone(tz) - timedelta(seconds=seconds_before))
      db.Session.commit()
      dlog("Flight time: %s" % flight.legs[0].depart.dt_formatted)
      if not blocking:
        print "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC) in", int(flight.seconds/60/60), "hrs", int(flight.seconds/60%60),  "mins from now..."
        t = Timer(flight.seconds, TryCheckinFlight, (res.id, flight.id, None, 1))
        t.daemon = True
        t.start()
        # DEBUG
        # if flight == res.flights[0]:
        #   Timer(5, TryCheckinFlight, (res, flight, None, 1)).start()
      else:
        scheduler.enterabs(flight.sched_time, 1, TryCheckinFlight, (res.id, flight.id, scheduler, 1))
        print "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC)"
      dlog('Checkin scheduled at (UTC): %s' % flight.sched_time_formatted)
      dlog('Checkin scheduled at (local): %s' % flight.sched_time_local_formatted)   
      dlog('Flights scheduled.  Waiting...')
    else:
      print 'Flight %s was successfully checked in at %s\n' % ((i+1), flight.position)
  db.isReservationActive(res)

def scheduleAllExistingReservations(confirm=False, blocking=False, scheduler=None):
  """ Load all existing reservations' flights for automatic checkin """
  reservations = db.getAllReservations()
  for res in reservations:
    if confirm:
      yes = raw_input('Would you like to schedule reservation %s for %s %s [Y/n]? ' % (res.code, res.first_name, res.last_name)).lower()
      if yes == 'y' or yes == '' or yes == 'yes':
        scheduleAllFlights(res, blocking, scheduler)
    else:
      print "Checking reservation %s for %s %s" % (res.code, res.first_name, res.last_name)
      scheduleAllFlights(res, blocking, scheduler)

# ========================================================================

def main():
  if (len(sys.argv) - 1) % 3 != 0 or len(sys.argv) < 4:
    yes = raw_input('Would you like to schedule an existing reservation from the database [Y/n]? ').lower()
    if yes == 'y' or yes == '' or yes == 'yes':
      sch = sched.scheduler(time_module.time, time_module.sleep)
      scheduleAllExistingReservations(confirm=True, blocking=True, scheduler=sch)
      sys.exit(1)
    else:    
      print 'Please provide name and confirmation code:'
      print '   %s <firstname> <lastname> <confirmation code> [...]' % sys.argv[0]
      sys.exit(1)

  args = sys.argv[1:]
  while len(args):
    (firstname, lastname, code) = args[0:3]
    res = db.findReservation(code)
    if res:
      print 'Reservation %s is already in the system...' % code
    else:
      res = db.addReservation(firstname, lastname, code)
    del args[0:3]

  global smtp_user, smtp_password, email_from, email_to, should_send_email

  sch = sched.scheduler(time_module.time, time_module.sleep)
  
  if should_send_email:
    if not email_from:
      email_from = raw_input('Email from: ');
    if email_from:
      if not email_to:
        email_to = raw_input('Email to: ');
      if not smtp_user:
        smtp_user = email_from
      if not smtp_password and smtp_auth:
        smtp_password = getpass.getpass('Email Password: ');
    else:
      should_send_email = False

  for res in db.Session.query(Reservation):
    if res.active:
      success = getFlightTimes(res)
      if success:
        displayFlightInfo(res, res.flights, True)
        scheduleAllFlights(res, blocking=True, scheduler=sch)
      else:
        db.isReservationActive(res)
        if res.active:
          db.deleteReservation(res)

  print 'Current time: %s' % DateTimeToString(datetime.now(utc))
  sch.run()

if __name__=='__main__':
  main()
