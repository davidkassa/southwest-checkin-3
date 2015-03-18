class SensitiveDataScrubber
  attr_reader :confirmation_number
  attr_reader :first_name
  attr_reader :last_name
  attr_reader :flight_numbers

  def initialize
    @flight_numbers = []
  end

  def setup(request_body, response_body)
    @confirmation_number ||= get_query_param_value(request_body, 'confirmationNumber') || get_query_param_value(request_body, 'recordLocator')
    @first_name ||= get_query_param_value(request_body, 'confirmationNumberFirstName') || get_query_param_value(request_body, 'firstName')
    @last_name ||= get_query_param_value(request_body, 'confirmationNumberLastName') || get_query_param_value(request_body, 'lastName')
    @flight_numbers += scan_flight_numbers(response_body)
    @flight_numbers.uniq!
  end

  def scan_flight_numbers(text)
    text.scan(/"flight_num":"([^,]*)"/).uniq.flatten
  end

  def get_query_param_value(params, key)
    matches = params.match(/#{key}=(.[^&]*)/)
    if matches
      matches.captures.any? ? matches.captures.first : nil
    end
  end

  def scrub!(text)
    text.sub!(/#{confirmation_number}/i, 'ABC123') if confirmation_number
    text.sub!(/#{first_name.upcase}/, 'FUU') if first_name
    text.sub!(/#{last_name.upcase}/, 'BAR') if last_name
    text.sub!(/#{first_name}/, 'Fuu') if first_name
    text.sub!(/#{last_name}/, 'Bar') if last_name
    text.sub!(/RR#.[0-9]*/, 'RR#12345678')
    text.sub!(/"rrNumber":".[^,}']*/, '"rrNumber":"12345678"')
    text.sub!(/"middleName":"MN:.[^,}']*/, '"middleName":"MN: B"')
    text.sub!(/"middleName":"[^MN:].[^,}']*/, '"middleName":"B"')
    text.sub!(/"cnclFirstName":".[^,}']*/, '"cnclFirstName":"FUU"')
    text.sub!(/"ebchkinfirstName":".[^,}']*/, '"ebchkinfirstName":"FUU"')
    text.sub!(/"chgFirstName":".[^,}']*/, '"chgFirstName":"FUU"')
    text.sub!(/"cnclLastName":".[^,}']*/, '"cnclLastName":"BAR"')
    text.sub!(/"sfreqLastName":".[^,}']*/, '"sfreqLastName":"BAR"')
    text.sub!(/"ebchkinlastName":".[^,}']*/, '"ebchkinlastName":"BAR"')
    text.sub!(/"chgLastName":".[^,}']*/, '"chgLastName":"BAR"')
    text.sub!(/"confirmationNumber":".[^,}']*/, '"confirmationNumber":"Confirmation #ABC123"')
    text.sub!(/"passengerName0":".[^,}']*/, '"passengerName0":"Fuu Bar"')
    text.sub!(/"firstName":".[^,}']*/, '"firstName":"Fuu"')
    text.sub!(/"lastName":".[^,}']*/, '"lastName":"Bar"')
    text.sub!(/"cnclConfirmNo":".[^,}']*/, '"cnclConfirmNo":"ABC123"')
    text.sub!(/"ebchkinConfNo":".[^,}']*/, '"ebchkinConfNo":"ABC123"')
    text.sub!(/"sfreqConfirmNo":".[^,}']*/, '"sfreqConfirmNo":"ABC123"')
    text.sub!(/"confirmNumber":".[^,}']*/, '"confirmNumber":"ABC123"')
    text.sub!(/"rrNumber":".[^,}']*/, '"rrNumber":"12345678"')
    text.sub!(/confirmationNumber=.[^&]*/, 'confirmationNumber=ABC123')
    text.sub!(/confirmationNumberFirstName=.[^&]*/, 'confirmationNumberFirstName=Fuu')
    text.sub!(/confirmationNumberLastName=.[^&]*/, 'confirmationNumberLastName=Bar')
    text.sub!(/"mbp_emailAddress":".[^,}']*/, '"mbp_emailAddress":"fuu@bar.com"')
    flight_numbers.each_with_index do |number, index|
      text.sub!(/#{number}/i, "#{1000 + index}")
    end
    text
  end
end
