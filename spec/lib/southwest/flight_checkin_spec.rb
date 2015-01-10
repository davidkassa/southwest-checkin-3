require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/flight_checkin'
require 'pry'

describe Southwest::FlightCheckin do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  subject(:checkin) {
    Southwest::FlightCheckin.new(
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  describe '#get_travel_info initializes the checkin' do
    let(:jsessionid) { '4A508841E779EB7E959D22737087FAE5' }
    let(:cacheid) { '124f9430192-ab08-4426-884d-1a38f231e349' }

    before do
      VCR.use_cassette 'getTravelInfo' do
        subject.get_travel_info
      end
    end

    it 'sets @jsessionid from cookie' do
      expect(subject.jsessionid).to eql(jsessionid)
    end

    it 'sets @cacheid from cookie' do
      expect(subject.cacheid).to eql(cacheid)
    end
  end

  describe '#check_intravel_alerts' do
    it 'returns a response' do
      VCR.use_cassette 'checkIntravelAlerts' do
        expect(JSON.parse(subject.check_intravel_alerts.body)['appState']).to eql('green')
      end
    end
  end

  describe '#checkin' do
    let(:expected_flight_information_keys) {
      ["arrivalCityCode", "stop1", "changeplaneImage", "departRouting", "wifiInfo", "departTime", "flightOperator", "departCityCode", "seperatorflag", "departCity", "stopmsg", "travelDate", "flightNumber", "date", "arrivalCityName", "arrivalTime", "traveltime", "scheduleDepart", "stop3", "stop2", "arriveCity"]
    }

    let(:expected_boarding_pass_details_keys) {
      ['mbpDepartDate', 'departCode', 'pass_rr_number', 'itineraryHeader', 'mbp_confirmationNumber', 'mbp_tier_status', 'mbprouting', 'arriveCode', 'departCity', 'mbpDepartTime', 'mbp_gateValue', 'itineraryRouting', 'arriveCity']
    }

    let(:expected_check_in_details_keys) {
      ["flight_num", "name", "pnr", "boardingroup_text", "position1_text"]
    }

    it 'returns 5 successful responses' do
      VCR.use_cassette 'checkin' do
        responses = subject.checkin
        responses[:raw].each { |k,v|
          expect(JSON.parse(v.body)['httpStatusCode']).to eql(200)
        }
      end
    end

    it 'returns flight information' do
      VCR.use_cassette 'checkin' do
        subject.checkin[:flight_information].each do |flight|
          expect(flight).to include(*expected_flight_information_keys)
        end
      end
    end

    it 'returns boarding pass details' do
      VCR.use_cassette 'checkin' do
        subject.checkin[:boarding_pass_details].each do |flight|
          expect(flight).to include(*expected_boarding_pass_details_keys)
        end
      end
    end

    it 'returns checkin details' do
      VCR.use_cassette 'checkin' do
        subject.checkin[:checkin_details].each do |flight|
          expect(flight).to include(*expected_check_in_details_keys)
        end
      end
    end
  end
end
