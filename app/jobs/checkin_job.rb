class CheckinJob < ActiveJob::Base
  queue_as :checkin

  def perform(flight)
    checkin_response = Southwest::Checkin.checkin(
      last_name: flight.reservation.last_name,
      first_name: flight.reservation.first_name,
      record_locator: flight.reservation.confirmation_number)

    checkin_record = Checkin.create({
      reservation: flight.reservation,
      payload: {
        flight_checkin_new: checkin_response.flight_checkin_new,
        get_all_boarding_passes: checkin_response.get_all_boarding_passes,
        view_boarding_passes: checkin_response.view_boarding_passes,
      }
    })

    if checkin_response.error?
      raise SouthwestCheckin::FailedCheckin, "The checkin for reservation '#{flight.reservation.id}' and flight '#{flight.id}' failed. Checkin record '#{checkin_record.id}' contains the payload.\n\nError:\n\t#{checkin_response.error}\n\n"
    end

    flight_checkins(checkin_response, checkin_record).each do |flight_attributes|
      FlightCheckin.create(flight_attributes)
    end
  end

  private

  def flight_checkins(checkin_response, checkin_record)
    CheckinParser.new(checkin_response, checkin_record).flight_checkins
  end
end
