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
  end
end
