require_relative './errors'

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
      responses = { raw: {} }

      responses[:raw][:get_travel_info] = get_travel_info
      breathe
      responses[:raw][:check_intravel_alerts] = check_intravel_alerts
      breathe
      responses[:raw][:flight_checkin_new] = flight_checkin_new
      responses[:flight_information] = JSON.parse(responses[:raw][:flight_checkin_new].body)['output']
      breathe
      responses[:raw][:get_all_boarding_passes] = get_all_boarding_passes
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
      response = Typhoeus::Request.post(base_uri, body: params, headers: headers)
      check_response!(response)
      store_cookies(response)
      response
    end

    def headers
      headers = { 'User-Agent' => user_agent }
      headers.merge!('Cookie' => cookie) if cookie
      headers
    end

    def cookie
      cookies = []
      cookies << "JSESSIONID=#{jsessionid}" if jsessionid
      cookies << "cacheid=#{cacheid}" if cacheid
      cookies.any? ? cookies.join('; ') : nil
    end

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

    def store_cookies(response)
      cookies = parse_cookies(response)
      @jsessionid = cookies['JSESSIONID'].first if cookies['JSESSIONID'].any?
      @cacheid = cookies['cacheid'].first if cookies['cacheid'].any?
    end

    def parse_cookies(response)
      if response.headers['Set-Cookie'].respond_to? :join
        cookie_string = response.headers['Set-Cookie'].join(';')
      else
        cookie_string = response.headers['Set-Cookie']
      end
      CGI::Cookie::parse(cookie_string)
    end

    def base_uri
      'https://mobile.southwest.com/middleware/MWServlet'
    end

    def user_agent
      'Southwest/2.10.0 CFNetwork/711.1.16 Darwin/14.0.0'
    end

    def validate_session!
      raise Southwest::InvalidCredentialsError, "A session must be created calling `flight_checkin_new` before a boarding passes can be retrieved." unless cacheid && jsessionid
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
