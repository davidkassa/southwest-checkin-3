module Southwest
  class FlightCheckin
    def self.checkin(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).checkin
    end

    attr_reader :last_name
    attr_reader :first_name
    attr_reader :record_locator

    def initialize(last_name:, first_name:, record_locator:)
      @last_name = last_name
      @first_name = first_name
      @record_locator = record_locator
      Southwest::Client.new.make_request(params)
    end

    def checkin
      check_intravel_alerts
      flight_checkin_new
      get_all_boarding_passes
      view_boarding_passes
    end

    def check_intravel_alerts
      response = make_request(check_intravel_alerts_params)
    end

    def flight_checkin_new
      response = make_request(flight_checkin_new_params)
    end

    def get_all_boarding_passes
      response = make_request(get_all_boarding_passes_params)
    end

    def view_boarding_passes
      response = make_request(get_all_boarding_passes_params)
    end

    private

    def check_intravel_alerts_params
      base_params.merge({
        serviceID: 'checkIntravelAlerts'
      })
    end

    def flight_checkin_new_params
      base_params.merge({
        serviceID: 'flightcheckin_new',
        lastName: last_name,
        firstName: first_name,
        recordLocator: record_locator
      })
    end

    def get_all_boarding_passes_params
      base_params.merge({
        serviceID: 'getallboardingpass'
      })
    end

    def view_boarding_passes_params
      base_params.merge({
        serviceID: 'viewboardingpass'
      })
    end

    def base_params
      {
        appID: 'swa',
        channe: 'rc',
        appver: '2.10.0',
        platform: 'iPhone',
        cacheid: ''
      }
    end

    def base_uri
      'https://mobile.southwest.com/middleware/MWServlet'
    end

    def make_request(params)
      Typhoeus::Request.new(base_uri,
        method: :post,
        params: params)
    end
  end
end
