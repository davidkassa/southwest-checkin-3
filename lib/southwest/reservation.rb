require_relative './request'

module Southwest
  class Reservation < Request
    def retrieve_reservation
      make_request(base_params.merge({
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
    end

    private

    def make_request(params)
      response = Typhoeus::Request.post(base_uri, body: params, headers: headers)
      store_cookies(response)
      response
    end

    # Example: '01/10/2015'
    def todays_date_formatted
      Time.now.strftime('%m/%d/%Y')
    end
  end
end
