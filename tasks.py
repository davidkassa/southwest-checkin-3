from celery import Celery
from sqlalchemy.orm import scoped_session

from settings import Config
config = Config()

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database
from sw_checkin_email import *

celery = Celery('tasks')
celery.config_from_object('celery_config')

if config["STORE_DATABASE"]:
  if config["HEROKU_DB"]:
    db = Database(heroku=True)
  elif config["POSTGRES_DB"] != '':
    db = Database(postgres=config["POSTGRES_DB"])
  else:
    db = Database(sqlite=config["SQLITE_DB"])
else:
  db = Database()

@celery.task(default_retry_delay=config["RETRY_INTERVAL"], max_retries=config["MAX_RETRIES"])
def check_in_flight(reservation_id, flight_id):
  session = scoped_session(db.session_factory)
  flight = session.query(Flight).get(flight_id)
  if flight.success:
    print "Skipping flight %d. Already checked in at %s" % (flight_id, flight.position)
    return

  reservation = session.query(Reservation).get(reservation_id)

  (position, boarding_pass) = getBoardingPass(reservation)

  if position:
    return check_in_success(reservation, flight, boarding_pass, position, session)
    session.remove()
  else:
    print 'FAILURE. Scheduling another try in %d seconds' % config["RETRY_INTERVAL"]
    session.remove()
    raise check_in_flight.retry(args=(reservation_id, flight_id))