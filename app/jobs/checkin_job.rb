class CheckinJob < ActiveJob::Base
  extend Cancelable
  queue_as :checkin

  def perform(flight)
    checkin = Southwest::Checkin.new(
      names: flight.reservation.passengers.map {|p|
        { last_name: p[:last_name], first_name: p[:first_name] }
      },
      record_locator: flight.reservation.confirmation_number)

    checkin_response = checkin.checkin

    checkin_record = Checkin.find_or_initialize_by(flight: flight)

    checkin_record.update!({
      payload: checkin_response.body
    })

    if checkin_response.code == 404
      checkin_record.update(error: checkin_response.body['message'], completed_at: Time.zone.now)
      return
    end

    if checkin_response.code >= 400
      perform(flight)
      raise Southwest::FailedCheckin, "The checkin for reservation '#{flight.reservation.id}' and flight '#{flight.id}' failed. Checkin record '#{checkin_record.id}' contains the payload.\n\nError:\n\t#{checkin_response.body['message']}\n\n"
    end

    if checkin_response.body['maxFailedCheckInAttemptsReached']
      checkin_record.update(error: 'Max failed check in attempts reached', completed_at: Time.zone.now)
      return
    end

    passenger_checkins(checkin_response, checkin_record).each do |flight_attributes|
      PassengerCheckin.create!(flight_attributes)
    end

    if checkin_record.user.present?
      checkin.email_boarding_passes(checkin_record.user.email)
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
