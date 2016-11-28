module Southwest
  class Checkin < Request
    def self.checkin(names:, record_locator:)
      new(names: names, record_locator: record_locator)
      .checkin(email_boarding_pass: email_boarding_pass)
    end

    attr_reader :names
    attr_reader :record_locator

    def initialize(names:, record_locator:)
      unless names && record_locator
        raise Southwest::RequestArgumentError, "names, record_locator are required"
      end

      @names = names
      @record_locator = record_locator
    end

    def checkin(email_boarding_pass: true)
      body = JSON.dump({ names: names_json })

      Response.new(make_request(checkin_url, body, checkin_content_type))
    end

    def email_boarding_passes(email)
      body = JSON.dump({ names: names_json, 'emailAddress' => email })

      Response.new(make_request(email_boarding_passes_url, body, email_content_type))
    end

    private

    def names_json
      @names_json ||= names.map {|n| { firstName: n[:first_name], lastName: n[:last_name] }}
    end

    def checkin_url
      "/reservations/record-locator/#{record_locator}/boarding-passes"
    end

    def email_boarding_passes_url
      "/record-locator/#{record_locator}/operation-infos/mobile-boarding-pass/notifications"
    end

    def make_request(path, body, content_type)
      Typhoeus::Request.post("#{base_uri}#{path}", {
        body: body, headers: headers(content_type)
      })
    end

    def email_content_type
      "application/vnd.swacorp.com.mobile.notifications-v1.0+json"
    end

    def checkin_content_type
      "application/vnd.swacorp.com.mobile.boarding-passes-v1.0+json"
    end
  end
end
