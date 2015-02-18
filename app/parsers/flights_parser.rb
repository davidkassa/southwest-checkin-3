class FlightsParser
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def flights
    departure_flights + return_flights
  end

  def departure_flights
    select_departure_flights.map do |k,v|
      flight(flight_key: k,
             flight_hash: v,
             departure_date_string: depart_date_string(v),
             arrival_date_string: depart_date_string(v),
             flight_number: depart_flight_number(v))
    end.sort_by { |flight| flight[:position] }
  end

  def return_flights
    select_return_flights.map do |k,v|
      flight(flight_key: k,
             flight_hash: v,
             departure_date_string: return_date_string(v),
             arrival_date_string: return_date_string(v),
             flight_number: return_flight_number(v))
    end.sort_by { |flight| flight[:position] }
  end

  private

  def flight(flight_key:, flight_hash:, departure_date_string:, arrival_date_string:, flight_number:)
    flight_time_departure = FlightTimeParser.new(city_string: flight_hash["departCity"], date_string: departure_date_string)
    flight_time_arrival = FlightTimeParser.new(city_string: flight_hash["arrivalCity"], date_string: arrival_date_string)

    # TODO: this determines if the flight spans multiple days (and
    # is less than 24 hours) and sets the correct day. Ideally, a response
    # would return 'returnArrivalDate' or 'departArrivalDate' if this is
    # the case, however, this has not yet been determined.
    if (flight_time_arrival.utc_datetime < flight_time_departure.utc_datetime)
      arrival_time = flight_time_arrival.utc_datetime + 1.day
    else
      arrival_time = flight_time_arrival.utc_datetime
    end

    {
      departure_time: flight_time_departure.utc_datetime,
      arrival_time: arrival_time,
      departure_city: flight_time_departure.city,
      arrival_city: flight_time_arrival.city,
      departure_airport: flight_time_departure.airport,
      arrival_airport: flight_time_arrival.airport,
      flight_type: flight_type(flight_key),
      position: flight_position(flight_key),
      flight_number: flight_number,
      payload: flight_hash
    }
  end

  def flight_position(flight_key)
    flight_key.match(/(Depart|Return)([0-9]*)/)[2]
  end

  def flight_type(flight_key)
    flight_key =~ /Return/i ? 1 : 0
  end

  def return_date_string(flight_hash)
    flight_hash["returnDate"] || select_return_flights.select {|k,v| v["returnDate"] }.first[1]["returnDate"]
  end

  def depart_date_string(flight_hash)
    flight_hash["departDate"] || select_departure_flights.select {|k,v| v["departDate"] }.first[1]["departDate"]
  end

  def return_flight_number(flight_hash)
    flight_hash["returnFlightNo"]
  end

  def depart_flight_number(flight_hash)
    flight_hash["departFlightNo"]
  end

  def select_departure_flights
    @select_departure_flights ||= info.select { |k,v| k.match /^Depart[0-9]+$/ }
  end

  def select_return_flights
    @select_return_flights ||= info.select { |k,v| k.match /^Return[0-9]+$/ }
  end

  def info
    json["upComingInfo"][0]
  end
end
