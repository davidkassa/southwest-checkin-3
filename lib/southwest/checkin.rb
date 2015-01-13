require_relative './request'

module Southwest
  class Checkin < Request
    def self.checkin(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).checkin
    end

    def checkin
      responses = { raw: {} }

      responses[:raw][:get_travel_info] = get_travel_info
      breathe
      responses[:raw][:check_intravel_alerts] = check_intravel_alerts
      breathe
      responses[:raw][:flight_checkin_new] = flight_checkin_new
      responses[:flight_information] = JSON.parse(responses[:raw][:flight_checkin_new].body)['output']
      breathe
      responses[:raw][:get_all_boarding_passes] = get_all_boarding_passes
      responses[:boarding_pass_details] = JSON.parse(responses[:raw][:get_all_boarding_passes].body)['mbpDetails']
      responses[:checkin_details] = JSON.parse(responses[:raw][:get_all_boarding_passes].body)['mbpPassenger']
      breathe
      responses[:raw][:view_boarding_passes] = view_boarding_passes

      responses
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
      ENV['RAILS_ENV'] = 'test'
    end
  end
end
