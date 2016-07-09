class CheckinParser
  attr_reader :checkin_response
  attr_reader :checkin_record

  def initialize(checkin_response, checkin_record)
    @checkin_response = checkin_response
    @checkin_record = checkin_record
  end

  def passenger_checkins
    checkin_response.body['passengerCheckInDocuments'].map do |doc|
      first_doc = doc['checkinDocuments'][0]
      {
        flight_number: flight_number(first_doc),
        boarding_group: first_doc['boardingGroup'],
        boarding_position: first_doc['boardingGroupNumber'],
        checkin: checkin_record,
        passenger: passenger(doc),
        flight: flight(first_doc),
      }
    end
  end

  def passenger(passenger_checkin_document)
    passengers = checkin_record.reservation.passengers
    if passengers.count == 1
      passengers.first
    else
      passengers.where(
        first_name: passenger_checkin_document['passenger']['secureFlightFirstName'],
        last_name: passenger_checkin_document['passenger']['secureFlightLastName']).first
    end
  end

  def flight(checkin_document)
    checkin_record.reservation.flights.where(flight_number: flight_number(checkin_document)).first
  end

  private

  def flight_number(checkin_document)
    checkin_document['flightNumber'] || checkin_document['carrierInfo']['flightNumber']
  end
end
