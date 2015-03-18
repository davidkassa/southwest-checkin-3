require_relative './request'

module Southwest
  class Reservation < Request
    def self.retrieve_reservation(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).retrieve_reservation
    end

    def retrieve_reservation
      typhoeus_response = make_request(base_params.merge({
        serviceID: 'viewAirReservation',
        searchType:  'ConfirmationNumber',
        submitButton: 'Continue',
        creditCardLastName: '',
        creditCardFirstName: '',
        confirmationNumber:  record_locator,
        confirmationNumberFirstName: first_name,
        confirmationNumberLastName:  last_name,
        creditCardDepartureDate: todays_date_formatted
      }))

      ReservationResponse.new(typhoeus_response)
    end

    private

    # Example: '01/10/2015'
    def todays_date_formatted
      Time.now.strftime('%m/%d/%Y')
    end
  end
end
