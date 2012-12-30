from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
from models import Base, Reservation

class Database:
  """ An interface to a SQLAlchemy database """

  def __init__(self, sqlite_name=':memory:', heroku=False):
    """ Initialize the database """
    if heroku:
      import os
      self.url = os.environ['DATABASE_URL']
    else:
      self.url = 'sqlite:///' + sqlite_name
    self.engine = create_engine(self.url)
    session_factory = sessionmaker(bind=self.engine)
    # The scoped_session is thread safe
    self.Session = scoped_session(session_factory)

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

  def isReservationActive(self, res):
    res.isReservationActive()
    self.Session.commit()
    if not res.active:
      print 'Reservation %s is no longer active.' % res.code

  def getAllReservations(self, active=True):
    if active:
      return self.Session.query(Reservation).filter_by(active = True).all()
    else:
      return self.Session.query(Reservation).all()


