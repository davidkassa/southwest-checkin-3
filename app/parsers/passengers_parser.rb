class PassengersParser
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def passengers
    json['passengers'].map do |passenger|
      secure_flight_name = passenger['secureFlightName']
      {
        first_name: secure_flight_name['firstName'],
        last_name: secure_flight_name['lastName'],
        full_name: full_name(secure_flight_name)
      }
    end
  end

  private

  def full_name(secure_flight_name)
    "#{secure_flight_name['firstName'].capitalize} #{secure_flight_name['lastName'].capitalize}"
  end
end
