require_relative './request'
require_relative './checkin_response'

module Southwest
  class Checkin < Request
    def self.checkin(last_name:, first_name:, record_locator:, email_boarding_pass: true)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).checkin(email_boarding_pass: email_boarding_pass)
    end

    def checkin(email_boarding_pass: true)
      create_session

      flight_checkin_new_response = Response.new(flight_checkin_new)

      if flight_checkin_new_response.error?
        return CheckinErrorResponse.new(flight_checkin_new: flight_checkin_new_response,
                                        error: flight_checkin_new_response.error)
      elsif missing_flight_information?(flight_checkin_new_response)
        return CheckinErrorResponse.new(flight_checkin_new: flight_checkin_new_response,
                                        error: "The request to 'flight_checkin_new' was successful, however the response had missing flight information. Check the response for more detail.")
      end

      breathe
      get_all_boarding_passes_response = Response.new(get_all_boarding_passes)

      if missing_boarding_pass_information?(get_all_boarding_passes_response)
        return CheckinErrorResponse.new(flight_checkin_new: flight_checkin_new_response,
                                        get_all_boarding_passes: get_all_boarding_passes_response,
                                        error: "The request to 'getallboardingpass' was successful, however the response had missing boarding pass information. Check the response for more detail.")
      end

      breathe
      if email_boarding_pass
        email_address = email_address_from_boarding_pass(get_all_boarding_passes_response)
      else
        email_address = nil
      end
      view_boarding_passes_response = Response.new(view_boarding_passes(email_address))

      CheckinResponse.new(flight_checkin_new: flight_checkin_new_response,
                          get_all_boarding_passes: get_all_boarding_passes_response,
                          view_boarding_passes: view_boarding_passes_response)
    end

    private

    def create_session
      get_travel_info_response = Response.new(get_travel_info)
      breathe
      check_intravel_alerts_response = Response.new(check_intravel_alerts)
      breathe
      return get_travel_info_response, check_intravel_alerts_response
    end

    def get_travel_info
      make_request(base_params.merge({
        serviceID: 'getTravelInfo'
      }))
    end

    def check_intravel_alerts
      make_request(base_params.merge({
        serviceID: 'checkIntravelAlerts'
      }))
    end

    def flight_checkin_new
      make_request(base_params.merge({
        serviceID: 'flightcheckin_new',
        lastName: last_name,
        firstName: first_name,
        recordLocator: record_locator
      }))
    end

    def get_all_boarding_passes
      validate_session!
      make_request(base_params.merge({
        serviceID: 'getallboardingpass'
      }))
    end

    def view_boarding_passes(email_address = nil)
      validate_session!
      params = { serviceID: 'viewboardingpass' }

      if email_address
        params[:optionEmail] = 'true'
        params[:emailAddress] = email_address
      else
        params[:optionPrint] = 'true'
      end

      make_request(base_params.merge(params))
    end

    def missing_flight_information?(response)
      response.body['output'].none?
    end

    def missing_boarding_pass_information?(response)
      response.body['Document'].none? && response.body['mbpPassenger'].none?
    end

    def is_cancelled_reservation?(response)
      response.body["errmsg"] =~ /cancelled/i
    end

    def email_address_from_boarding_pass(response)
      email = response.body['mbp_emailAddress']
      email.present? ? email : nil
    end

    # These endpoints return JSON with a custom response
    # code attribute called `httpStatusCode`. This method
    # validates that the HTTP response code and the
    # `httpStatusCode` attribute are valid.
    def check_response!(response)
      unless response_ok?(response)
        raise Southwest::RequestError, "There was an error making the request. It returned a status of #{status(response)}. Response:\n#{response}"
      end
    end

    def response_ok?(response)
      return false if response.code >= 400
      code = status(response)
      code < 400
    end

    def status(response)
      JSON.parse(response.body)['httpStatusCode']
    end

    def breathe
      sleep 3 unless test_env?
    end

    # Rails isn't necessary loaded in test,
    # so don't use `Rails.env.test?`
    def test_env?
      @test_env ||= ENV['RAILS_ENV'] == 'test'
    end
  end
end
