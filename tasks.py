from sets import Set
from celery import Celery
from sqlalchemy.orm import scoped_session

from settings import Config
config = Config()

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database
from sw_checkin_email import *

celery = Celery('tasks')
celery.config_from_object('celery_config')

from celery.utils.log import get_task_logger
logger = get_task_logger(__name__)

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

@celery.task()
def update_all_reservation_activity():
  print "[Task] Updating all reservations..."
  session = scoped_session(db.session_factory)
  reservations = session.query(Reservation).filter_by(active = True).all()
  count = 0
  for res in reservations:
    for (i, flight) in enumerate(res.flights):
      flight_time = time_module.mktime(flight.legs[0].depart.dt_utc.utctimetuple()) - time_module.timezone
      if flight_time < time_module.time():
        flight.active = False
    res.isReservationActive()
    if not res.active:
      count += 1
    session.commit()
  session.remove()
  print "[Task] Marked %d reservations as inactive..." % count

@celery.task()
def delete_inactive_old_reservations():
  session = scoped_session(db.session_factory)
  reservations = session.query(Reservation).filter_by(active = False).all()
  res_count = 0
  for res in reservations:
    session.delete(res)
    res_count += 1
  session.commit()

  active_flight_leg_location_ids = []
  legs = session.query(FlightLeg).all()

  for leg in legs:
    active_flight_leg_location_ids.append(leg.depart_id)
    active_flight_leg_location_ids.append(leg.arrive_id)

  all_flight_leg_locations = session.query(FlightLegLocation).all()
  all_flight_leg_location_ids = map((lambda x: x.id), all_flight_leg_locations)
  inactive_flight_location_ids = Set(all_flight_leg_location_ids) - Set(active_flight_leg_location_ids)

  location_count = 0
  for location_id in inactive_flight_location_ids:
    location = session.query(FlightLegLocation).get(location_id)
    session.delete(location)
    location_count += 1
  session.commit()

  session.remove()
  print "[Task] Deleted %d reservations" % res_count
  print "[Task] Deleted %d leg locations" % location_count

@celery.task()
def schedule_all_existing_reservations():
  logger.info("Scheduling all existing reservations....")
  session = scoped_session(db.session_factory)
  reservations = session.query(Reservation).filter_by(active = True).all()
  for res in reservations:
    logger.info("Checking reservation %s for %s %s" % (res.code, res.first_name, res.last_name))
    scheduleAllFlights(res)

  session.commit()
  session.remove()
