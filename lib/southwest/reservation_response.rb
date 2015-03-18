module Southwest
  class ReservationResponse < Response
    def arrival_city_name
      body["upComingInfo"][0]["arrivalCityName"]
    end

    def international?
      body["isInternationalPNR"] == 'true'
    end

    def entered_incorrectly?
      error.match /entered correctly/
    end

    def cancelled?
      error.match /cancelled/
    end
  end
end
