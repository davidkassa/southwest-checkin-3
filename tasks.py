from celery import Celery
from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database

celery = Celery('tasks')
celery.config_from_object('celery_config')

@celery.task
def add(x, y):
    return x + y

@celery.task
def schedule_checkin(flight_id):
  db = Database('test.db')
  flight = db.Session.query(Flight).get(flight_id)
  print "Found flight %s" % flight.id
  # print "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC) in", int(flight.seconds/60/60), "hrs", int(flight.seconds/60%60),  "mins from now..."
  # t = Timer(flight.seconds, TryCheckinFlight, (reservation.id, flight.id, None, 1))