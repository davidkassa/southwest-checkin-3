class CheckinJob < ActiveJob::Base
  queue_as :checkin

  def perform(flight)
    Southwest::Checkin.checkin(
      last_name: flight.reservation.last_name,
      first_name: flight.reservation.first_name,
      record_locator: flight.reservation.confirmation_number)
  end
end
