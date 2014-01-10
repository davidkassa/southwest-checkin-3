from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import (Column, Integer, ForeignKey, 
  String, Float, DateTime, Boolean)
from sqlalchemy.orm import relationship, backref

Base = declarative_base()

class FlightLegLocation(Base):
  """ Represents an airport at a specific point in time
      corresponding to a scheduled departure or arrival of a flight.

      Attributes:
        airport: airport 3-letter code
        tz: timezone
        dt: departure or arrival time
        dt_utc: departure or arrival time in UTC
        dt_formatted: departure or arrival time formatted to string
      
      Known Issues:
        - This isn't a well-defined entity and is likely to cause
          confusion, errors, or incorrect use in calling code.
  """
  __tablename__ = 'flight_leg_location'
  id = Column(Integer, primary_key=True)
  # flightleg_id = Column(Integer, ForeignKey('flight_leg.id'))
  airport = Column(String(3))
  # tz: don't store this in the database
  dt = Column(DateTime())
  dt_formatted = Column(String())
  dt_utc = Column(DateTime())
  dt_utc_formatted = Column(String())
  

class FlightLeg(Base):
  """ Represents a segment of a flight from an airport to the
      next airport.

      Attributes:
        flight_number: the flight number, format: '#123'
        depart: a FlightLegLocation for the departure city
        arrive: a FlightLegLocation for the arrival city

      Reference for multiple joins (depart and arrive):
        http://docs.sqlalchemy.org/en/rel_0_7/orm/relationships.html#setting-the-primaryjoin-and-secondaryjoin
  """
  __tablename__ = 'flight_leg'
  id = Column(Integer, primary_key=True)
  flight_id = Column(Integer, ForeignKey('flight.id'))
  flight_number = Column(String(6))
  
  depart_id = Column(Integer, ForeignKey("flight_leg_location.id"))
  arrive_id = Column(Integer, ForeignKey("flight_leg_location.id"))
  depart = relationship("FlightLegLocation",
                    primaryjoin="FlightLegLocation.id==FlightLeg.depart_id")
  arrive = relationship("FlightLegLocation",
                    primaryjoin="FlightLegLocation.id==FlightLeg.arrive_id")

  # depart = relationship("FlightLegLocation", uselist=False, backref='flight') #, foreign_keys=[depart_id])
  # arrive = relationship("FlightLegLocation", uselist=False) #, foreign_keys=[arrive_id])

  def __repr__(self):
    return '<Flight Leg: %r>' % self.flight_number


class Flight(Base):
  """ A flight goes from an origin airport to a destination airport.
      It consists of one or more FlightLegs.

      Attributes:
        legs: a list of FlightLegs
  """
  __tablename__ = 'flight'
  id = Column(Integer, primary_key=True)
  reservation_id = Column(Integer, ForeignKey('reservation.id'))
  legs = relationship("FlightLeg", backref='flight')
  active = Column(Boolean(), default=True)
  success = Column(Boolean(), default=False)
  position = Column(String())
  sched_time = Column(Float())
  sched_time_formatted = Column(String())
  sched_time_local_formatted = Column(String())
  seconds = Column(Float())
  task_uuid = Column(String())

  def task_status(self):
    if self.task_uuid == None: return False
    from celery.result import AsyncResult
    return AsyncResult(self.task_uuid).state


class Reservation(Base):
  """ Represents a reservation.
      A reservation is identified by a 6-character confirmation code.
      It can have one or more people on it and can have one or more
      flights.
      
      KNOWN ISSUES:
      - This table links a single code with a single person.
        Adding more than one person with the same code will cause
        an error or an overwrite of the reservation.
        This shouldn't affect check-in as all people on the reservation
        will be checked in.
  """
  __tablename__ = 'reservation'
  id = Column(Integer, primary_key=True)
  first_name = Column(String())
  last_name = Column(String())
  code = Column(String(6), unique=True)
  active = Column(Boolean(), default=True)
  new = Column(Boolean(), default=True)
  email = Column(String())
  flights = relationship("Flight", backref='reservation', cascade="all, delete, delete-orphan")

  def __init__(self, first_name, last_name, code, email=None):
    self.first_name = first_name
    self.last_name = last_name
    self.code = code
    self.email = email

  def __repr__(self):
    return '<Reservation: %r>' % self.code

  def isReservationActive(self):
    if len(self.flights) > 0:
      active = False
      for flight in self.flights:
        if flight.active: 
          active = True
      self.active = active
    else:
      self.active = False
