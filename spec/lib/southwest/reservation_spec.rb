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
    let(:response_json) { subject.retrieve_reservation[:reservation] }
    let(:expected_person_keys) {
      ["isCompanion", "cnclFirstName", "confirmationNumber", "Depart2", "Depart1", "cnclLastName", "passengerName0", "TripName", "isFlNotifAvailable", "cnclConfirmNo", "arrivalCityName"]
    }

    let(:expected_flight_keys) {
      ["departCity", "arrivalCity", "departFlightNo"]
    }

    it 'returns upComingInfo' do
      VCR.use_cassette 'viewAirReservation' do
        expect(response_json['upComingInfo']).to_not eql(nil)
      end
    end

    it 'contains the correct keys for each person on the reservation' do
      VCR.use_cassette 'viewAirReservation' do
        response_json['upComingInfo'].each do |person|
          expect(person).to include(*expected_person_keys)
        end
      end
    end

    it 'contains the correct information for each flight' do
      VCR.use_cassette 'viewAirReservation' do
        response_json['upComingInfo'].each do |person|
          person.select { |k,v| k =~ /Depart/ }.each do |key, flight|
            expect(flight).to include(*expected_flight_keys)
          end
        end
      end
    end
  end
end
