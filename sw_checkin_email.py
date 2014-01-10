#!/usr/bin/env python

# The MIT License
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

# Load settings
from settings import Config
config = Config()

from db import Database
from tasks import *

# ========================================================================

base_url = 'http://www.southwest.com'
checkin_url = urlparse.urljoin(base_url, '/flight/retrieveCheckinDoc.html')
retrieve_url = urlparse.urljoin(base_url, '/flight/lookup-air-reservation.html')

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

# International Time Zones
tz_aruba = timezone('America/Aruba')
tz_bermuda = timezone('Atlantic/Bermuda')
tz_sd = timezone('America/Santo_Domingo')
tz_pr = timezone('America/Puerto_Rico')

airport_timezone_map = {
  'ABQ': tz_mountain,
  'ALB': tz_eastern,
  'AMA': tz_central,
  'ATL': tz_eastern,
  'AUA': tz_aruba,
  'AUS': tz_central,
  'BDA': tz_bermuda,
  'BDL': tz_eastern,
  'BHM': tz_central,
  'BKG': tz_central,
  'BNA': tz_central,
  'BOI': tz_mountain,
  'BOS': tz_eastern,
  'BUF': tz_eastern,
  'BUR': tz_pacific,
  'BWI': tz_eastern,
  'CAK': tz_eastern,
  'CHS': tz_eastern,
  'CLE': tz_eastern,
  'CLT': tz_eastern,
  'CMH': tz_eastern,
  'CRP': tz_central,
  'CUN': tz_central,
  'DAL': tz_central,
  'DAY': tz_eastern,
  'DCA': tz_eastern,
  'DEN': tz_mountain,
  'DSM': tz_central,
  'DTW': tz_eastern,
  'ECP': tz_central,
  'ELP': tz_mountain,
  'EWR': tz_eastern,
  'EYW': tz_eastern,
  'FLL': tz_eastern,
  'FNT': tz_eastern,
  'GEG': tz_pacific,
  'GRR': tz_eastern,
  'GSP': tz_eastern,
  'HOU': tz_central,
  'HRL': tz_central,
  'IAD': tz_eastern,
  'ICT': tz_central,
  'IND': tz_eastern,
  'ISP': tz_eastern,
  'JAN': tz_central,
  'JAX': tz_eastern,
  'LAS': tz_pacific,
  'LAX': tz_pacific,
  'LBB': tz_central,
  'LGA': tz_eastern,
  'LIT': tz_central,
  'MAF': tz_central,
  'MBJ': tz_eastern,
  'MCI': tz_central,
  'MCO': tz_eastern,
  'MDW': tz_central,
  'MEM': tz_central,
  'MEX': tz_central,
  'MHT': tz_eastern,
  'MKE': tz_central,
  'MSP': tz_central,
  'MSY': tz_central,
  'NAS': tz_eastern,
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
  'PNS': tz_central,
  'PUJ': tz_sd,
  'PVD': tz_eastern,
  'PWM': tz_eastern,
  'RDU': tz_eastern,
  'RIC': tz_eastern,
  'RNO': tz_pacific,
  'ROC': tz_eastern,
  'RSW': tz_eastern,
  'SAN': tz_pacific,
  'SAT': tz_central,
  'SDF': tz_eastern,
  'SEA': tz_pacific,
  'SFO': tz_pacific,
  'SJC': tz_pacific,
  'SJD': tz_mountain,
  'SJU': tz_pr,
  'SLC': tz_mountain,
  'SMF': tz_pacific,
  'SNA': tz_pacific,
  'STL': tz_central,
  'TPA': tz_eastern,
  'TUL': tz_central,
  'TUS': tz_arizona,
}

# =========== function definitions =======================================

# Log debug messages to console
def dlog(str):
  if config["VERBOSE"]:
    print 'DEBUG: %s' % str

if config["STORE_DATABASE"]:
  if config["HEROKU_DB"]:
    db = Database(heroku=True)
  elif config["POSTGRES_DB"] != '':
    db = Database(postgres=config["POSTGRES_DB"])
  else:
    db = Database(sqlite=config["SQLITE_DB"])
else:
  db = Database()
db.create_all()

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
    print 'Cannot GET: %s' % url
    raise e

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
    print 'Cannot POST: %s' % url
    raise e

  return (resp.read(), resp.geturl())

def FindAllByTagClass(soup, tag, klass, get_text=False):
  result = soup.find_all(tag,
      attrs = { 'class': re.compile(re.escape(klass)) })
  if get_text:
    return strip_tags(unicode(result))
  else:
    return result

def FindByTagClass(soup, tag, klass, get_text=False):
  result = soup.find(tag,
      attrs = { 'class': re.compile(re.escape(klass)) })
  if get_text:
    return strip_tags(unicode(result))
  else:
    return result

def FindNextSiblingByTagClass(soup, tag, klass):
  return soup.find_next_sibling(tag,
      attrs = { 'class': re.compile(re.escape(klass)) })

from HTMLParser import HTMLParser

# A clean solution for stripping tags, which BS4 doesn't do
# Credit: http://stackoverflow.com/a/925630/1114945
class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()

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
    if config["DEBUG_HTML_FILES"]:
      f = codecs.open('html_data_' + str(datetime.now()) + '.html', encoding='utf-8', mode='w+')
      f.write(str(data))
      f.close

    form = soup.find('form', id=id)
    print
    if form == None:
      print("Couldn't find the HTML form to lookup the flight! Did the web page change? Or are we too early?")
      return None
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
      raise StandardError('Too many submit buttons checked on form!')

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
    
    '''
    Since we only check in to flights with the given confirmation number, 
    we do not want to include any 'associated products' with other confirmation 
    numbers. The following 4 lines of code grab just the flights with our 
    confirmation number, omitting any other flights.

    NOTE: The 'associated products' (flights with differing confirmation 
    numbers) are located inside the tag <h3 class="trip_associated_products">. 
    We could use this to add a feature, wherein the user can opt to check in 
    to all associated flights.
    '''
    
    flights_with_relevant_confirmation_code = soup.find_all('div',
        {'class',"trip_retrieved_product"})
    if len(flights_with_relevant_confirmation_code)>1:
        raise Exception(
            'We should only have one trip retrieved product! Something is wrong!')
    soup = flights_with_relevant_confirmation_code[0]

    # The table containing departure flights
    airItineraryDepartTable = soup.find_all('table', id="airItinerarydepart")
    # The table containing return flights
    airItineraryReturnTable = soup.find_all('table', id="airItineraryreturn")

    dlog("Checking reservation departure flights...")
    if airItineraryDepartTable:
      self.exists = True
      self._addFlights(airItineraryDepartTable)
    else:
      print "Can't find a departure flight... are we sure this reservation exists?"
      self.exists = False

    dlog("Checking reservation return flights...")
    if airItineraryReturnTable:
      self._addFlights(airItineraryReturnTable)
    else:
      dlog("You don't have a return flight.")

  def _addFlights(self, table):
    for item in table:
      flight = self._parseFlightInfo(item)
      # If we already have the flight number, don't add it again
      if not any(flight.legs[0].flight_number in f.legs[0].flight_number for f in self.flights):
        self.flights.append(flight)

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
      flight_leg.flight_number = strip_tags(unicode(parent.strong))
      print "Found flight", flight_leg.flight_number

      # List of arrival and departure details for each airport
      flight_leg_soup = tr.find('table', 'airItineraryFlightRouting').find_all('tr')
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
    segmentTime = FindByTagClass(legDetails, 'td', 'routingDetailsTimes', get_text=True)
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
    return (None, None)

  # Need to check all of the passengers
  for i in form.inputs:
    if i.type == 'checkbox' and i.name.startswith('checkinPassengers'):
      i.checked = True

  # This is the button to press
  form.setSubmit('printDocuments')

  # finally, lets check in the flight and make our success file
  (checkinresult, form_url) = form.submit()
  if config["DEBUG_HTML_FILES"]:
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

def check_in_success(reservation, flight, boarding_pass, position, session):
  flight.success = True
  flight.position = position
  session.commit()
  send_success_email(success_message(reservation, flight), boarding_pass, reservation)
  return

def success_message(reservation, flight):
  message = ''
  message += 'SUCCESS.  Checked in at position %s\r\n' % flight.position
  message += getFlightInfo(reservation, [flight])
  return message

def send_success_email(message, boarding_pass, reservation):
  if hasattr(reservation, 'email'):
    send_email('Flight checked in!', message, boarding_pass, reservation.email)
  else:
    send_email('Flight checked in!', message, boarding_pass)
  send_email('%s %s was checked in' % (reservation.first_name, reservation.last_name), message, boarding_pass, config["ADMIN_EMAIL"])

def TryCheckinFlight(res_id, flight_id, sch, attempt):
  session = scoped_session(db.session_factory)
  res = session.query(Reservation).filter_by(id=res_id).one()
  flight = session.query(Flight).filter_by(id=flight_id).one()
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
    session.commit()
    if hasattr(res, 'email'):
      send_email('Flight checked in!', message, boarding_pass, res.email)
    else:
      send_email('Flight checked in!', message, boarding_pass)
    send_email('%s %s was checked in' % (res.first_name, res.last_name), message, boarding_pass, config["ADMIN_EMAIL"])
    session.remove()
  else:
    session.remove()
    if attempt > config["MAX_RETRIES"]:
      print 'FAILURE.  Too many failures, giving up.'
    else:
      print 'FAILURE.  Scheduling another try in %d seconds' % config["RETRY_INTERVAL"]
      if (sch): # Traditional scheduler - command line
        sch.enterabs(time_module.time() + config["RETRY_INTERVAL"], 1,
                     TryCheckinFlight, (res.id, flight.id, sch, attempt + 1))
      else: # Async timer - Flask
        t = Timer(config["RETRY_INTERVAL"], TryCheckinFlight, (res.id, flight.id, None, attempt + 1))
        t.daemon = True
        t.start()

def send_email(subject, message, boarding_pass=None, email=None):
  if not config["SEND_EMAIL"] or not config["SEND_ADMIN_EMAIL"]: return

  if email is not None:
    config["EMAIL_TO"] = email

  dlog("Sending email to:" + config["EMAIL_TO"])
  for to in [string.strip(s) for s in string.split(config["EMAIL_TO"], ',')]:
    try:
      smtp = smtplib.SMTP(config["SMTP_SERVER"], config["SMTP_PORT"])
      smtp.ehlo()
      if config["SMTP_USE_TLS"]:
        smtp.starttls()
      smtp.ehlo()
      if config["SMTP_AUTH"]:
        smtp.login(config["SMTP_USER"], config["SMTP_PASSWORD"])
      print 'Sending mail to %s.' % to
      msg = MIMEMultipart('mixed')
      msg['Subject'] = subject
      msg['To'] = to
      msg['From'] = config["EMAIL_FROM"]
      msg.attach(MIMEText(message, 'plain'))
      if boarding_pass:
        msg_bp = MIMEText(boarding_pass, 'html')
        msg_bp.add_header('content-disposition', 'attachment', filename='boarding_pass.html')
        msg.attach(msg_bp)
      smtp.sendmail(config["EMAIL_FROM"], to, msg.as_string())

      print 'Email sent successfully.'
      smtp.close()
    except Exception, e:
      print 'Error sending email!'
      raise e

def scheduleFlight(res, flight, blocking=False, scheduler=None):
  flight_time = time_module.mktime(flight.legs[0].depart.dt_utc.utctimetuple()) - time_module.timezone
  seconds_before = config["CHECKIN_WINDOW"] + 24*60*60 # how many seconds before the flight time do we check in
  flight.sched_time = flight_time - seconds_before
  flight.sched_time_formatted = DateTimeToString(flight.legs[0].depart.dt_utc.replace(tzinfo=utc) - timedelta(seconds=seconds_before))
  flight.seconds = flight.sched_time - time_module.time()
  # Retrieve timezone and apply it because datetimes are stored as naive (no timezone information)
  tz = airport_timezone_map[flight.legs[0].depart.airport]
  flight.sched_time_local_formatted = DateTimeToString(flight.legs[0].depart.dt_utc.replace(tzinfo=utc).astimezone(tz) - timedelta(seconds=seconds_before))
  db.Session.commit()
  dlog("Flight time: %s" % flight.legs[0].depart.dt_formatted)
  if config["CELERY"]:
    result = check_in_flight.apply_async([res.id, flight.id], countdown=flight.seconds)
    flight.task_uuid = result.id
    db.Session.commit()
  elif not blocking:
    result = "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC) in", int(flight.seconds/60/60), "hrs", int(flight.seconds/60%60),  "mins from now..."
    t = Timer(flight.seconds, TryCheckinFlight, (res.id, flight.id, None, 1))
    t.daemon = True
    t.start()
    # DEBUG
    # if flight == res.flights[0]:
    #   Timer(5, TryCheckinFlight, (res, flight, None, 1)).start()
  else:
    scheduler.enterabs(flight.sched_time, 1, TryCheckinFlight, (res.id, flight.id, scheduler, 1))
    result = "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC)"
  print result
  dlog('Checkin scheduled at (UTC): %s' % flight.sched_time_formatted)
  dlog('Checkin scheduled at (local): %s' % flight.sched_time_local_formatted)
  dlog('Flights scheduled.  Waiting...')
  return result

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
      scheduleFlight(res, flight, blocking, scheduler)
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

  # global config["SMTP_USER"], config["SMTP_PASSWORD"], config["EMAIL_FROM"], config["EMAIL_TO"], config["SEND_EMAIL"]

  sch = sched.scheduler(time_module.time, time_module.sleep)

  if config["SEND_EMAIL"]:
    if not config["EMAIL_FROM"]:
      config["EMAIL_FROM"] = raw_input('Email from: ');
    if config["EMAIL_FROM"]:
      if not config["EMAIL_TO"]:
        config["EMAIL_TO"] = raw_input('Email to: ');
      if not config["SMTP_USER"]:
        config["SMTP_USER"] = config["EMAIL_FROM"]
      if not config["SMTP_PASSWORD"] and config["SMTP_AUTH"]:
        config["SMTP_PASSWORD"] = getpass.getpass('Email Password: ');
    else:
      config["SEND_EMAIL"] = False

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
