require 'spec_helper'
require_relative '../../../lib/southwest/flight_checkin'

describe Southwest::FlightCheckin do
  it 'puts out the arguments' do
    Southwest::FlightCheckin.new(
      last_name: 'Foo',
      first_name: 'Bar',
      record_locator: 'ABC123')
  end
end
