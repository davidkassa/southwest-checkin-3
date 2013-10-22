import unittest
from mock import patch, MagicMock

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database

from tasks import *

class DatabaseTestCase(unittest.TestCase):
    def setUp(self):
        self.db = Database()
        self.db.create_all()

class ReservationTestCase(DatabaseTestCase):
    def setUp(self):
        super(ReservationTestCase, self).setUp()
        self.setUpReservation()
        self.setUpFlight(self.reservation)
        self.setUpFlightLeg(self.reservation)
        self.setUpFlightLocation(self.reservation)
        self.db.Session.add(self.reservation)
        self.db.Session.commit()

    def setUpReservation(self):
        self.code = '999999'
        self.reservation = Reservation('Bob', 'Smith', self.code, 'email@email.com')

    def setUpFlight(self, reservation):
        flights = []
        flights.append(Flight())
        flights[0].sched_time = 10.0
        flights.append(Flight())
        reservation.flights = flights

    def setUpFlightLeg(self, reservation):
        reservation.flights[0].legs.append(FlightLeg())
        reservation.flights[1].legs.append(FlightLeg())
        reservation.flights[0].legs[0].flight_number = "1234"

    def setUpFlightLocation(self, reservation):
        reservation.flights[0].legs[0].depart = FlightLegLocation()
        reservation.flights[0].legs[0].depart.airport = 'AUS'

    def tearDown(self):
        self.db.deleteReservation(self.reservation)


class CreateReservationTestCase(ReservationTestCase):
    def runTest(self):
        self.assertEqual(self.db.findReservation(self.code).first_name, 'Bob', 'Incorrect first name')

class CreateFlightTestCase(ReservationTestCase):
    def runTest(self):
        self.assertEqual(self.db.findReservation(self.code).flights[0].sched_time, 10.0, 'Incorrect scheduled time.')

class CreateFlightLegTestCase(ReservationTestCase):
    def runTest(self):
        self.assertEqual(self.db.findReservation(self.code).flights[0].legs[0].flight_number, "1234", 'Incorrect flight number.')

class CreateFlightLegLocationTestCase(ReservationTestCase):
    def runTest(self):
        self.assertEqual(self.db.findReservation(self.code).flights[0].legs[0].depart.airport, 'AUS', 'Incorrect flight location.')

class CheckInFlightTestCase(ReservationTestCase):
    def setUp(self):
        super(CheckInFlightTestCase, self).setUp()
        import tasks
        tasks.getBoardingPass = MagicMock(return_value=[1, 1])
        tasks.check_in_success = MagicMock()

    def runTest(self):
        check_in_flight(self.reservation.id, self.reservation.flights[0].id)

if __name__ == '__main__':
    unittest.main()