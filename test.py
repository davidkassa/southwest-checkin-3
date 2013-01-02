#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Usage:
#
#   The default environment is a local database in memory.
#
#   python test.py --environment <heroku|sqlite|memory>

from clint import args
from clint.textui import puts, colored, indent

errors = []
def record_error(message, e):
  errors.append([message, e])

env  = 'memory' # default
if args.contains('--environment'):
  arg = args.grouped['--environment'][0]
  if arg == 'heroku':
    env = 'heroku'
  if arg == 'sqlite':
    env = 'sqlite'
puts('Environment: %s' % env)

# ========================================================================
# Database
# ========================================================================

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database

if env == 'memory':
  db = Database()
elif env == 'sqlite':
  db = Database('test.db')
elif env == 'heroku':
  db = Database(heroku=True)

db.create_all()

puts('Adding a reservation...')
try:
  res = Reservation('Bob', 'Smith', '999999', 'email@email.com')
  db.Session.add(res)
  db.Session.commit()
except Exception, e:
  record_error('Failed on adding the reservation', e)

puts('Adding a flight...')
try:
  flights = []
  flights.append(Flight())
  flights[0].sched_time = 10.0
  flights.append(Flight())
  res.flights = flights
  db.Session.commit()
except Exception, e:
  record_error('Failed on adding the flight', e)

puts('Adding a flight leg...')
try:
  res.flights[0].legs.append(FlightLeg())
  res.flights[1].legs.append(FlightLeg())
  res.flights[0].legs[0].flight_number = "1234"
  db.Session.commit()
except Exception, e:
  record_error('Failed on adding a flight leg', e)

puts('Adding a flight location...')
try:
  res.flights[0].legs[0].depart = FlightLegLocation()
  res.flights[0].legs[0].depart.airport = 'AUS'
  db.Session.commit()
except Exception, e:
  record_error('Failed on adding the reservation', e)

puts('Querying data...')
try:
  for instance in db.Session.query(Reservation): 
    with indent(4, quote='>'):
      puts('Reservation: %s %s' % (instance.first_name, instance.code))
      puts('First flight scheduled time: %s ' % str(instance.flights[0].sched_time))
      puts('First flight, first leg, flight #: %s' % instance.flights[0].legs[0].flight_number)
      puts("First flight, first leg location's airport: %s" % instance.flights[0].legs[0].depart.airport)
except Exception, e:
  record_error('Failed on querying', e)

if env == 'heroku':
  try:
    puts('Deleting test data from Heroku database...')
    db.deleteReservation(res)
  except Exception, e:
    record_error('Failed on deletion', e)

if env == 'sqlite':
  try:
    puts('Deleting sqlite test database...')
    from os import remove
    remove('test.db')
  except Exception, e:
    record_error('Failed to delete test database', e)

# ========================================================================
# Email
# ========================================================================

# blah

# ========================================================================
# Results
# ========================================================================

if len(errors) == 0:
  puts(colored.green('Success!'))
else:
  puts(colored.red(':( There were some errors:'))
  for i, e in enumerate(errors, 1):
    puts(colored.red('ERROR %s:' % i))
    with indent(4, quote=colored.red('>')):
      puts('Message: %s' % e[0])
      puts('Exception: %s' % e[1])
