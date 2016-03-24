module Southwest
  class Response
    attr_accessor :response_body
    attr_accessor :headers
    attr_accessor :code
    attr_accessor :status_message
    attr_accessor :typhoeus_response

    def initialize(response)
      @typhoeus_response = response
      @response_body     = try_to_parse(response.body)
      @headers           = response.headers
      @code              = response.code
      @status_message    = response.status_message
    end

    def to_hash
      %w{body headers code status_message}.each_with_object({}) do |a, hash|
        hash[a.to_sym] = self.send(a)
      end
    end

    # `body` is not allowed as an instance variable name
    def body
      response_body
    end

    def error?
      code >= 400
    end

    def error_message
      error? and body['message']
    end

    private

    def try_to_parse(string)
      JSON.parse(string)
    rescue
      return string
    end
  end
end
