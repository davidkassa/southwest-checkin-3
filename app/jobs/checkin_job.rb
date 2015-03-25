class CheckinJob < ActiveJob::Base
  extend Cancelable
  queue_as :checkin

  def perform(flight)
    checkin_response = Southwest::Checkin.checkin(
      last_name: flight.reservation.last_name,
      first_name: flight.reservation.first_name,
      record_locator: flight.reservation.confirmation_number)

    checkin_record = Checkin.find_or_initialize_by(flight: flight)

    checkin_record.update!({
      payload: {
        flight_checkin_new: checkin_response.flight_checkin_new,
        get_all_boarding_passes: checkin_response.get_all_boarding_passes,
        view_boarding_passes: checkin_response.view_boarding_passes,
      }
    })

    if checkin_response.error?
      if checkin_response.incorrect_passenger? || checkin_response.cancelled_reservation?
        checkin_record.update(error: checkin_response.error, completed_at: Time.zone.now)
        return
      else
        raise SouthwestCheckin::FailedCheckin, "The checkin for reservation '#{flight.reservation.id}' and flight '#{flight.id}' failed. Checkin record '#{checkin_record.id}' contains the payload.\n\nError:\n\t#{checkin_response.error}\n\n"
      end
    end

    passenger_checkins(checkin_response, checkin_record).each do |flight_attributes|
      PassengerCheckin.create(flight_attributes)
    end

    if checkin_record.user.present?
      CheckinMailer.successful_checkin(checkin_record, checkin_record.user.email).deliver_later
    end

    # Finally, mark the checkin completed
    checkin_record.update!(completed_at: Time.zone.now)
  end

  private

  def passenger_checkins(checkin_response, checkin_record)
    CheckinParser.new(checkin_response, checkin_record).passenger_checkins
  end
end
