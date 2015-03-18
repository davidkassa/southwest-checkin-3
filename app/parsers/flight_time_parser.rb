# This class takes a departure and date string returned by
# the Southwest API and extracts the relevant information:
#
#   - UTC datetime
#   - corresponding `Airport` record
#   - city string
#
class FlightTimeParser
  attr_reader :city_string
  attr_reader :date_string

  def initialize(city_string:, date_string:)
    @city_string = city_string
    @date_string = date_string
  end

  def utc_datetime
    time_in_zone.utc.to_datetime
  end

  def time_in_zone
    Time.use_zone(airport.timezone) do
      Time.zone.parse("#{time_string}, #{date_string}")
    end
  end

  def city
    /\d{1,2}:\d{2}\ [APap][Mm]\ (?<city>.*)\ \([[:alpha:]]*\)/.match(city_string)[:city].try(:strip)
  end

  def airport
    Airport.find_by_iata!(iata)
  end

  def iata
    city_string.scan(/\(([[:alpha:]]*)\)/).last.first
  end

  private

  def time_string
    /^\d{1,2}:\d{2}\ [APap][Mm]/.match(city_string)
  end
end
