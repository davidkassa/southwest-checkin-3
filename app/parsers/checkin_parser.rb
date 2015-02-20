class CheckinParser
  attr_reader :checkin_response
  attr_reader :checkin_record

  def initialize(checkin_response, checkin_record)
    @checkin_response = checkin_response
    @checkin_record = checkin_record
  end

  def passenger_checkins
    if checkin_response.multiple_passengers?
      flight_checkins_for_multiple_passengers
    else
      flight_checkin_for_single_passenger
    end
  end

  def flight_checkin_for_single_passenger
    checkin_response.single_passenger_documents.map do |doc_json|
      doc = CheckinDocument.new(doc_json)
      flight_checkin(doc)
    end
  end

  def flight_checkins_for_multiple_passengers
    previous = nil
    checkin_response.multiple_passenger_documents.map do |doc_json|
      doc = CheckinDocument.new(doc_json)

      if doc.full_name.present?
        previous = doc
      end

      flight_checkin(doc, previous.full_name)
    end
  end

  def flight_checkin(doc, previous_full_name=nil)
    {
      flight_number: doc.flight_number,
      boarding_group: doc.boarding_group,
      boarding_position: doc.boarding_position,
      flight: flights[doc.flight_number],
      passenger: find_passenger_record(doc.full_name, previous_full_name),
      checkin_id: checkin_record.id
    }
  end

  def flights
    flights ||= checkin_response.flight_information.each_with_object({}) do |flight_json, hash|
      hash[flight_json["flightNumber"]] = find_flight_record(flight_json)
    end
  end

  private

  # Multi-passenger checkins do not always contain a name to identify
  # the passenger. In this case, we use the name from the previous
  # passenger document.
  def find_passenger_record(full_name, fallback_full_name=nil)
    reservation.passengers.where(full_name: full_name).first || begin
      if fallback_full_name
        reservation.passengers.where(full_name: fallback_full_name).first
      else
        nil
      end
    end
  end

  def reservation
    checkin_record.flight.reservation
  end

  def find_flight_record(flight_json)
    departure_airport = Airport.find_by_iata(flight_json["departCityCode"])
    arrival_airport = Airport.find_by_iata(flight_json["arrivalCityCode"])

    raise SouthwestCheckin::AirportNotFound, "#{flight_json["departCityCode"]} airport cound not be found." unless departure_airport
    raise SouthwestCheckin::AirportNotFound, "#{flight_json["arrivalCityCode"]} airport cound not be found" unless arrival_airport

    reservation.flights.where(departure_airport_id: departure_airport.id, arrival_airport_id: arrival_airport.id).try(:first)
  end
end
