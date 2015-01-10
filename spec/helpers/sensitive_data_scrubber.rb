def sensitive_data_scrubber(text, number: nil, first: nil, last: nil, flight_numbers: [])
  text.sub!(/#{number}/i, 'ABC123') if number
  text.sub!(/#{first.upcase}/, 'FUU') if first
  text.sub!(/#{last.upcase}/, 'BAR') if last
  text.sub!(/#{first}/, 'Fuu') if first
  text.sub!(/#{last}/, 'Bar') if last
  text.sub!(/RR#.[0-9]*/, 'RR#12345678')
  text.sub!(/"rrNumber":".[^,]*/, '"rrNumber":"12345678"')
  text.sub!(/"middleName":"MN:.[^,]*/, '"middleName":"MN: B"')
  text.sub!(/"middleName":"[^MN:].[^,]*/, '"middleName":"B"')
  flight_numbers.each_with_index do |number, index|
    text.sub!(/#{number}/i, "#{1000 + index}")
  end
end
