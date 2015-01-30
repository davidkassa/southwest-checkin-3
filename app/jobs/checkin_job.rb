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

    flights(checkin_response, checkin_record).each do |flight_attributes|
      FlightCheckin.create(flight_attributes)
    end
  end

  private

  def flights(checkin_response, checkin_record)
    CheckinParser.new(checkin_response, checkin_record).flights
  end
end
