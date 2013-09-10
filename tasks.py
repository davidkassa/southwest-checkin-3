from celery import Celery

celery = Celery('tasks',
  broker='redis://localhost:6379/0',
  backend='redis://localhost')

@celery.task
def add(x, y):
    return x + y

@celery.task
def schedule_checkin(flight, reservation):
  print "Scheduling check in for flight at", flight.legs[0].depart.dt_formatted, "(local), ", flight.legs[0].depart.dt_utc_formatted, "(UTC) in", int(flight.seconds/60/60), "hrs", int(flight.seconds/60%60),  "mins from now..."
  # t = Timer(flight.seconds, TryCheckinFlight, (reservation.id, flight.id, None, 1))