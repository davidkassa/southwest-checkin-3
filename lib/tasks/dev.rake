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
    }).first_or_create!
  end
end

def checkin_reservation(cassette, reservation)
  if reservation.checkins.count == 0
    VCR.use_cassette cassette do
      flight = reservation.flights.where(position: 1).first
      checkin_flight(flight)
    end
  end
end

def checkin_flight(flight)
  Rails.application.config.active_job.queue_adapter = :inline
  checkin = Checkin.find_or_initialize_by(flight: flight)
  checkin.scheduled_at = Time.zone.now
  checkin.save!

  job = CheckinJob.perform_later(flight)

  checkin.update({ job_id: job.job_id })
end

namespace :dev do
  desc "Load the database with development seed data"
  task prime: :environment do
    require 'vcr'
    require_relative '../../spec/helpers/vcr_helper'

    reservation_cassette = 'record_locator_view_multi_LAX_2016-03-18'
    checkin_cassette = 'record_locator_checkin_LAX_2016-03-18'

    fuu = create_user
    reservation = create_reservation(reservation_cassette, fuu)
    checkin_reservation(checkin_cassette, reservation)
  end
end
