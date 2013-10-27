from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
from models import Base, Reservation

class Database:
  """ An interface to a SQLAlchemy database """

  def __init__(self, sqlite=':memory:', heroku=False, postgres=False):
    """ Initialize the database """
    if heroku:
      import os
      self.url = os.environ['DATABASE_URL']
      self.engine = create_engine(self.url)
    elif postgres:
      self.url = postgres
      self.engine = create_engine(self.url)
    else:
      self.url = 'sqlite:///' + sqlite
      from sqlalchemy.pool import StaticPool
      # special args for memory db -> http://docs.sqlalchemy.org/en/rel_0_7/dialects/sqlite.html#using-a-memory-database-in-multiple-threads
      self.engine = create_engine(self.url, connect_args={'check_same_thread':False},
                    poolclass=StaticPool)
    self.session_factory = sessionmaker(bind=self.engine)
    # The scoped_session is thread safe
    self.Session = scoped_session(self.session_factory)

  def create_all(self):
    """ Create tables if they don't exist """
    Base.metadata.create_all(self.engine)

  def addReservation(self, first_name, last_name, code, email=None):
    res = Reservation(first_name, last_name, code, email)
    self.Session.add(res)
    self.Session.commit()
    return res

  def deleteReservation(self, res):
      self.Session.delete(res)
      self.Session.commit()

  def findReservation(self, code):
    query = self.Session.query(Reservation).filter_by(code = code)
    try:
      res = query.one()
    except:
      return None
    return res

  def findReservationsByEmail(self, email):
    reservations = self.Session.query(Reservation).filter_by(email = email).all()
    if len(reservations) == 0:
      return None
    return reservations

  def isReservationActive(self, res):
    res.isReservationActive()
    self.Session.commit()
    if not res.active:
      print 'Reservation %s is no longer active.' % res.code

  def getAllReservations(self, active=True):
    try:
      if active:
        return self.Session.query(Reservation).filter_by(active = True).all()
      else:
        return self.Session.query(Reservation).all()
    except:
      return None


