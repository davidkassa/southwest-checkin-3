class PassengersParser
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def passengers
    passenger_full_name_keys.map do |k|
      if k == main_passenger_key
        main_passenger
      else
        { full_name: info[k] }
      end
    end
  end

  private

  def main_passenger
    {
      is_companion: info["isCompanion"],
      first_name: info["cnclFirstName"],
      last_name: info["cnclLastName"],
      full_name: info[main_passenger_key]
    }
  end

  def main_passenger_key
    "passengerName0"
  end

  def passenger_full_name_keys
    info.keys.select { |k| k =~ /passengerName/ }
  end

  def info
    json["upComingInfo"][0]
  end
end
