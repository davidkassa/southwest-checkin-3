class PassengersParser
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def passengers
    [
      {
        is_companion: info["isCompanion"],
        first_name: info["cnclFirstName"],
        last_name: info["cnclLastName"],
        full_name: info["passengerName0"]
      }
    ]
  end

  private

  def info
    json["upComingInfo"][0]
  end
end
