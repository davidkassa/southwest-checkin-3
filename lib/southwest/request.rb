require_relative './errors'

module Southwest
  class Request
    attr_reader :last_name
    attr_reader :first_name
    attr_reader :record_locator

    def initialize(last_name:, first_name:, record_locator:)
      unless last_name && first_name && record_locator
        raise Southwest::RequestArgumentError, "last_name, first_name, record_locator are required"
      end

      @last_name = last_name
      @first_name = first_name
      @record_locator = record_locator
    end

    protected

    def make_request(path, params, content_type)
      Typhoeus::Request.get("#{base_uri}#{path}", {
        params: params, headers: headers(content_type)
      })
    end

    def headers(content_type)
      {
        'User-Agent' => user_agent,
        'Content-Type' => content_type,
        'X-Api-Key' => api_key,
        'Accept-Language' => 'en-US;q=1'
      }
    end

    def base_uri
      'https://api-extensions.southwest.com/v1/mobile'
    end

    def user_agent
      "Southwest/3.3.7 (iPhone; iOS 9.3; Scale/2.00)"
    end

    def api_key
      "l7xx8d8bfce4ee874269bedc02832674129b"
    end
  end
end
