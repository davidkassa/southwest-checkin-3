module Southwest
  class Reservation < Request
    def self.retrieve_reservation(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).retrieve_reservation
    end

    def retrieve_reservation
      typhoeus_response = make_request("/reservations/record-locator/#{record_locator}", {
        action: 'VIEW',
        'first-name' => first_name,
        'last-name' => last_name
      }, content_type)

      Response.new(typhoeus_response)
    end

    private

    def content_type
      "application/vnd.swacorp.com.mobile.reservations-v1.0+json"
    end
  end
end
