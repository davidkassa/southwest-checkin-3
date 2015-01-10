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
    attr_reader :cacheid
    attr_reader :jsessionid

    def initialize(last_name:, first_name:, record_locator:)
      @last_name = last_name
      @first_name = first_name
      @record_locator = record_locator
    end

    def checkin
      get_travel_info
      check_intravel_alerts
      flight_checkin_new
      get_all_boarding_passes
      view_boarding_passes
    end

    def get_travel_info
      response = make_request(get_travel_info_params)
      cookies = parse_cookies(response)
      @jsessionid = cookies['JSESSIONID'].first if cookies['JSESSIONID']
      @cacheid = cookies['cacheid'].first if cookies['cacheid']
      response
    end

    def check_intravel_alerts
      make_request(check_intravel_alerts_params)
    end

    def flight_checkin_new
      make_request(flight_checkin_new_params)
    end

    def get_all_boarding_passes
      make_request(get_all_boarding_passes_params)
    end

    def view_boarding_passes
      make_request(get_all_boarding_passes_params)
    end

    private

    def get_travel_info_params
      base_params.merge({
        serviceID: 'getTravelInfo'
      })
    end

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
        channel: 'rc',
        appver: '2.10.0',
        platform: 'iPhone',
        cacheid: ''
      }
    end

    def make_request(params)
      Typhoeus::Request.post(base_uri, body: params, headers: headers)
    end

    def headers
      headers = { 'User-Agent' => user_agent }
      headers.merge('Cookie' => cookie) if cookie
      headers
    end

    def cookie
      cookies = []
      cookies << "JSESSIONID=#{jsessionid}" if jsessionid
      cookies << "cacheid=#{cacheid}" if cacheid
      cookies.any? ? cookies.join('; ') : nil
    end

    def parse_cookies(response)
      CGI::Cookie::parse(response.headers['Set-Cookie'].join(';'))
    end

    def base_uri
      'https://mobile.southwest.com/middleware/MWServlet'
    end

    def user_agent
      'Southwest/2.10.0 CFNetwork/711.1.16 Darwin/14.0.0'
    end
  end
end
