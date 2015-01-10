require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/flight_checkin'
require 'pry'

describe Southwest::FlightCheckin do
  subject(:checkin) {
    Southwest::FlightCheckin.new(
      last_name: 'Foo',
      first_name: 'Bar',
      record_locator: 'ABC123')
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
end
