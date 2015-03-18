require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/reservation'

RSpec.describe Southwest::Reservation do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  subject {
    Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  shared_examples_for 'successful reservation retrieval' do
    let(:expected_keys) {
      ["isCompanion", "cnclFirstName", "confirmationNumber", "cnclLastName", "passengerName0", "TripName", "isFlNotifAvailable", "cnclConfirmNo", "arrivalCityName"]
    }

    let(:expected_depart_flight_keys) {
      ["departCity", "arrivalCity", "departFlightNo"]
    }

    let(:expected_return_flight_keys) {
      ["departCity", "arrivalCity", "returnFlightNo"]
    }

    it 'returns upComingInfo' do
      VCR.use_cassette cassette do
        expect(subject.body['upComingInfo']).to_not eql(nil)
      end
    end

    it 'contains the correct keys detailing the passenger' do
      VCR.use_cassette cassette do
        subject.body['upComingInfo'].each do |person|
          expect(person).to include(*expected_keys)
        end
      end
    end

    it 'contains the correct information for each departure flight' do
      VCR.use_cassette cassette do
        subject.body['upComingInfo'].each do |person|
          person.select { |k,v| k =~ /Depart/ }.each do |key, flight|
            expect(flight).to include(*expected_depart_flight_keys)
          end
        end
      end
    end

    it 'contains the correct information for each return flight' do
      VCR.use_cassette 'viewAirReservation multi' do
        subject.body['upComingInfo'].each do |person|
          person.select { |k,v| k =~ /Return/ }.each do |key, flight|
            expect(flight).to include(*expected_return_flight_keys)
          end
        end
      end
    end
  end

  describe "'Austin, TX - Denver, CO' reservation" do
    it_behaves_like 'successful reservation retrieval' do
      let(:cassette) { 'viewAirReservation' }
    end
  end

  describe "1 stop return flight" do
    it_behaves_like 'successful reservation retrieval' do
      let(:cassette) { 'viewAirReservation multi' }
    end
  end

  describe 'cancelled reservation' do
    it 'returns a cancelled error message' do
      VCR.use_cassette 'viewAirReservation cancelled' do
        expect(subject.error).to eql("Your reservation has been cancelled  (SW107028)")
      end
    end
  end

  describe 'Multiple passengers reservation - SFO to BWI' do
    let(:cassette) { 'viewAirReservation multiple passengers sfo bwi 1 stop' }

    it_behaves_like 'successful reservation retrieval'
  end

  describe 'checkin 5 - multiple passengers on a reservation' do
    let(:cassette) { 'viewAirReservation multiple passengers mco pit nonstop' }

    it_behaves_like 'successful reservation retrieval'
  end

  describe 'single passenger reservation' do
    let(:cassette) { 'viewAirReservation single MDW MCI' }

    it_behaves_like 'successful reservation retrieval'
  end

  describe 'bad reservation information' do
    let(:cassette) { 'bad reservation information' }

    it 'returns an error that the reservation does not exist' do
      VCR.use_cassette cassette do
        expect(subject.error).to match(/We were unable to retrieve your reservation from our database/)
      end
    end
  end

  describe 'international flight' do
    let(:cassette) { 'international flight Punta Cana DO' }

    it "returns 'isInternationalPNR' indicating it is international" do
      VCR.use_cassette cassette do
        expect(subject.body["isInternationalPNR"]).to eql('true')
      end
    end
  end
end
