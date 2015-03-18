# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'csv'

puts "== db:seed"
puts "-- airports"

airports_file = File.read(Rails.root.join('db', 'seeds', 'airports.dat'))
CSV.parse(airports_file).each do |row|
  airport = Airport.find_or_initialize_by(airport_id: row[0])
  airport.update!(
    name: row[1],
    city: row[2],
    country: row[3],
    iata: row[4],
    icao: row[5],
    latitude: row[6].to_f,
    longitude: row[7].to_f,
    altitude: row[8],
    timezone_offset: row[9],
    dst: row[10],
    timezone: row[11]
  )
end

puts "== DONE db:seed"
