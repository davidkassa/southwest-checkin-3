import unittest
# from unittest.mock import MagicMock

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database

class SouthwestCheckinTestCase(unittest.TestCase):
    def setUp(self):
        self.db = Database()
        self.db.create_all()

class ReservationTestCase(SouthwestCheckinTestCase):
    def setUp(self):
        super(ReservationTestCase, self).setUp()
        self.reservation = Reservation('Bob', 'Smith', '999999', 'email@email.com')
        self.db.Session.add(self.reservation)
        self.db.Session.commit()

class ReservationFirstNameTestCase(ReservationTestCase):
    def runTest(self):
        self.assertEqual(self.reservation.first_name, 'Bob', 'Incorrect first name')

if __name__ == '__main__':
    unittest.main()