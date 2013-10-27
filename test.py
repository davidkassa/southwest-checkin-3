#! /usr/bin/env python
# -*- coding: utf-8 -*-

from clint import args
from clint.textui import puts, colored, indent

import unittest
from mock import patch, MagicMock
from datetime import datetime

from models import Reservation, Flight, FlightLeg, FlightLegLocation
from db import Database

from sw_checkin_email import *
from tasks import *

class EmailTestCase(unittest.TestCase):
    def setUp(self):
        self.email_to = 'sw.automatic.checkin@gmail.com'

    def runTest(self):
        send_email('Southwest Checkin Test ' + str(datetime.now()), 'Test email body', boarding_pass=None, email=self.email_to)

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
        self.setUpEmailMock()

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
        reservation.flights[0].legs[0].arrive = FlightLegLocation()
        reservation.flights[0].legs[0].arrive.airport = 'MCI'

    def setUpEmailMock(self):
        import sw_checkin_email
        sw_checkin_email.send_email = MagicMock()

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
        tasks.db = MagicMock(return_value=self.db)

    def runTest(self):
        check_in_flight(self.reservation.id, self.reservation.flights[0].id)

class CheckInSuccessTestCase(ReservationTestCase):
    def runTest(self):
        check_in_success(self.reservation, self.reservation.flights[0], "Boarding Pass", 1, self.db.Session)

class SuccessMessageTestCase(CheckInSuccessTestCase):
    def runTest(self):
        self.assertEqual(success_message(self.reservation, self.reservation.flights[0]), u'SUCCESS.  Checked in at position None\r\nConfirmation number: 999999\r\nPassenger name: Bob Smith\r\nFlight 1:\n  Flight Number: 1234\n    Departs: AUS None (None)\n    Arrives: MCI None (None)\n')

if __name__ == '__main__':
    unittest.main()
