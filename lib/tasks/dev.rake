require 'vcr'
require_relative '../../spec/helpers/vcr_helper'

def create_user
  User.where(email:'fuu.bar@baz.com').first_or_create do |user|
    user.password = 'password'
  end
end

def create_reservation(cassette, user)
  reservation = nil
  VCR.use_cassette cassette do
    reservation = user.reservations.where({
      confirmation_number: "ABC123",
      first_name: "Fuu",
      last_name: "Bar"
    }).first_or_create
  end
end

def checkin_flight(cassette, reservation)
  if !reservation.checkin
    VCR.use_cassette cassette do
      flight = reservation.flights.where(position: 1).first
      Rails.application.config.active_job.queue_adapter = :inline
      CheckinJob.perform_later(flight)
    end
  end
end

namespace :dev do
  desc "Load the database with development seed data"
  task prime: :environment do
    reservation_cassette = 'viewAirReservation multiple passengers sfo bwi 1 stop'
    checkin_cassette = 'checkin multiple passengers sfo bwi 1 stop'

    fuu = create_user
    reservation = create_reservation(reservation_cassette, fuu)
    checkin_flight(checkin_cassette, reservation)
  end
end
