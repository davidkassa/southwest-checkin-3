class FlightsParser
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def flights
    departure = true
    json['itinerary']['originationDestinations'].map do |destination|
      position = 1
      flights = destination['segments'].map do |segment|
        departure_airport = Airport.find_by_iata!(segment['originationAirportCode'])
        arrival_airport = Airport.find_by_iata!(segment['destinationAirportCode'])

        flight = {
          departure_time: segment['departureDateTime'],
          arrival_time: segment['arrivalDateTime'],
          departure_city: departure_airport.name,
          arrival_city: arrival_airport.name,
          payload: segment,
          departure_airport: departure_airport,
          arrival_airport: arrival_airport,
          flight_type: departure ? 'departure' : 'return',
          position: position,
          flight_number: segment['operatingCarrierInfo']['flightNumber']
        }
        position += 1
        flight
      end

      departure = false
      flights
    end.flatten
  end
end
