require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/reservation'

describe Southwest::Reservation do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  subject {
    Southwest::Reservation.new(
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  describe '#retrieve_reservation' do
    it 'returns upComingInfo' do
      VCR.use_cassette 'viewAirReservation' do
        expect(JSON.parse(subject.retrieve_reservation.body)['upComingInfo']).to_not eql(nil)
      end
    end
  end
end
