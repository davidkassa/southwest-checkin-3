def flight_numbers(text)
  text.scan(/"flight_num":"([^,]*)"/).uniq
end

def get_query_param_value(params, key)
  matches = params.match(/#{key}=(.[^&]*)/)
  if matches
    matches.captures.any? ? matches.captures.first : nil
  end
end

def sensitive_data_scrubber(text, confirmation_number: nil, first_name: nil,
                            last_name: nil, flight_numbers: [])
  text.sub!(/#{confirmation_number}/i, 'ABC123') if confirmation_number
  text.sub!(/#{first_name.upcase}/, 'FUU') if first_name
  text.sub!(/#{last_name.upcase}/, 'BAR') if last_name
  text.sub!(/#{first_name}/, 'Fuu') if first_name
  text.sub!(/#{last_name}/, 'Bar') if last_name
  text.sub!(/RR#.[0-9]*/, 'RR#12345678')
  text.sub!(/"rrNumber":".[^,]*/, '"rrNumber":"12345678"')
  text.sub!(/"middleName":"MN:.[^,]*/, '"middleName":"MN: B"')
  text.sub!(/"middleName":"[^MN:].[^,]*/, '"middleName":"B"')
  text.sub!(/"cnclFirstName":".[^,]*/, '"cnclFirstName":"FUU"')
  text.sub!(/"ebchkinfirstName":".[^,]*/, '"ebchkinfirstName":"FUU"')
  text.sub!(/"chgFirstName":".[^,]*/, '"chgFirstName":"FUU"')
  text.sub!(/"cnclLastName":".[^,]*/, '"cnclLastName":"BAR"')
  text.sub!(/"sfreqLastName":".[^,]*/, '"sfreqLastName":"BAR"')
  text.sub!(/"ebchkinlastName":".[^,]*/, '"ebchkinlastName":"BAR"')
  text.sub!(/"chgLastName":".[^,]*/, '"chgLastName":"BAR"')
  text.sub!(/"confirmationNumber":".[^,]*/, '"confirmationNumber":"Confirmation #ABC123"')
  text.sub!(/"passengerName0":".[^,]*/, '"passengerName0":"Fuu Bar"')
  text.sub!(/"firstName":".[^,]*/, '"firstName":"Fuu"')
  text.sub!(/"lastName":".[^,]*/, '"lastName":"Bar"')
  text.sub!(/"cnclConfirmNo":".[^,]*/, '"cnclConfirmNo":"ABC123"')
  text.sub!(/"ebchkinConfNo":".[^,]*/, '"ebchkinConfNo":"ABC123"')
  text.sub!(/"sfreqConfirmNo":".[^,]*/, '"sfreqConfirmNo":"ABC123"')
  text.sub!(/"confirmNumber":".[^,]*/, '"confirmNumber":"ABC123"')
  text.sub!(/"rrNumber":".[^,]*/, '"rrNumber":"12345678"')
  text.sub!(/confirmationNumber=.[^&]*/, 'confirmationNumber=ABC123')
  text.sub!(/confirmationNumberFirstName=.[^&]*/, 'confirmationNumberFirstName=Fuu')
  text.sub!(/confirmationNumberLastName=.[^&]*/, 'confirmationNumberLastName=Bar')
  flight_numbers.each_with_index do |number, index|
    text.sub!(/#{number}/i, "#{1000 + index}")
  end
end
