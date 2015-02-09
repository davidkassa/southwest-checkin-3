require_relative './errors'

module Southwest
  class Request
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

    protected

    def base_params
      {
        appID: 'swa',
        channel: 'rc',
        appver: app_version,
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

    def check_response!(response)
      if response.code >= 400
        raise Southwest::RequestError, "There was an error making the request. It returned a status of #{status(response)}. Response:\n#{response}"
      end
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
      "Southwest/#{app_version} CFNetwork/711.1.16 Darwin/14.0.0"
    end

    def app_version
      "2.10.1"
    end

    def validate_session!
      raise Southwest::InvalidCredentialsError, "A session must be created by calling `flight_checkin_new` before a boarding passes can be retrieved." unless cacheid && jsessionid
    end
  end
end
