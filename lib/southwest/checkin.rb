module Southwest
  class Checkin < Request
    def self.checkin(last_name:, first_name:, record_locator:)
      new(last_name: last_name,
          first_name: first_name,
          record_locator: record_locator).checkin(email_boarding_pass: email_boarding_pass)
    end

    def checkin(email_boarding_pass: true)
      body = JSON.dump({
        names: [{ 'firstName' => first_name, 'lastName' => last_name }]
      })

      Response.new(make_request(checkin_url, body, checkin_content_type))
    end

    def email_boarding_passes(email)
      body = JSON.dump({
        names: [{ 'firstName' => first_name, 'lastName' => last_name }],
        'emailAddress' => email
      })

      Response.new(make_request(email_boarding_passes_url, body, email_content_type))
    end

    private

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
