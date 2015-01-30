class CheckinParser
  attr_reader :checkin_response
  attr_reader :checkin_record

  def initialize(checkin_response, checkin_record)
    @checkin_response = checkin_response
    @checkin_record = checkin_record
  end

  def flights
    checkin_response.flight_information.map do |flight_json|
      flight_record = find_flight_record(flight_json)
      checkin_details = checkin_details_for(flight_json)
      {
        flight: flight_record,
        checkin: checkin_record,
        boarding_group: checkin_details["boardingroup_text"],
        boarding_position: checkin_details["position1_text"],
        flight_number: flight_json["flightNumber"]
      }
    end
  end

  private

  def find_flight_record(flight_json)
    departure_airport = Airport.find_by_iata(flight_json["departCityCode"])
    arrival_airport = Airport.find_by_iata(flight_json["arrivalCityCode"])

    raise SouthwestCheckin::AirportNotFound, "#{flight_json["departCityCode"]} airport cound not be found." unless departure_airport
    raise SouthwestCheckin::AirportNotFound, "#{flight_json["arrivalCityCode"]} airport cound not be found" unless arrival_airport

    checkin_record.reservation.flights.where(departure_airport_id: departure_airport.id, arrival_airport_id: arrival_airport.id).try(:first)
  end

  def checkin_details_for(flight_json)
    checkin_response.checkin_details.select { |c| c["flight_num"] == flight_json["flightNumber"] }.first
  end
end
