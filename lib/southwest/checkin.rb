require_relative './request'
require_relative './checkin_response'

module Southwest
  class Checkin < Request
    def self.checkin(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).checkin
    end

    def checkin
      flight_checkin_new_response = Response.new(flight_checkin_new)

      if flight_checkin_new_response.error?
        return CheckinErrorResponse.new(flight_checkin_new: flight_checkin_new_response,
                                        error: flight_checkin_new_response.error)
      end

      breathe
      get_all_boarding_passes_response = Response.new(get_all_boarding_passes)
      breathe
      view_boarding_passes_response = Response.new(view_boarding_passes)

      CheckinResponse.new(flight_checkin_new: flight_checkin_new_response,
                          get_all_boarding_passes: get_all_boarding_passes_response,
                          view_boarding_passes: view_boarding_passes_response)
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

    def view_boarding_passes
      validate_session!
      make_request(base_params.merge({
        serviceID: 'viewboardingpass',
        optionPrint: 'true'
      }))
    end

    private

    def is_cancelled_reservation?(response)
      response.body["errmsg"] =~ /cancelled/i
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
      sleep 0.5 unless test_env?
    end

    # Rails isn't necessary loaded in test,
    # so don't use `Rails.env.test?`
    def test_env?
      @test_env ||= ENV['RAILS_ENV'] == 'test'
    end
  end
end
