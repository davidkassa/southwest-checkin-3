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
    it 'matches the JSON schema for a record locator view' do
      VCR.use_cassette cassette do
        expect(subject.body).to match_json_schema(:record_locator_view)
      end
    end
  end

  describe "valid reservations" do
    describe 'domestic, round trip, multi-passenger, passenger #1' do
      it_behaves_like 'successful reservation retrieval' do
        let(:cassette) { 'record locator view multi LAX 2016-03-18' }
      end
    end

    describe 'domestic, round trip, multi-passenger, passenger #2' do

      it_behaves_like 'successful reservation retrieval' do
        let(:cassette) { 'record locator view multi LAX 2016-03-18 passenger 2' }
        let(:last_name) { 'Smith' }
        let(:first_name) { 'John' }
        let(:record_locator) { 'DEF123' }
      end
    end

    describe 'domestic, round trip, single-passenger' do
      it_behaves_like 'successful reservation retrieval' do
        let(:cassette) { 'record locator view BOS 2016-03-18' }
      end
    end

    describe 'international trip' do
      it_behaves_like 'successful reservation retrieval' do
        let(:cassette) { 'international 2016-07-08' }
      end
    end
  end

  describe 'cancelled reservation' do
    skip 'returns a cancelled error message' do
      VCR.use_cassette 'viewAirReservation cancelled' do
        expect(subject.error).to eql("Your reservation has been cancelled  (SW107028)")
      end
    end
  end

  describe 'invalid reservation' do
    let(:cassette) { 'record locator view invalid 2016-03-18' }

    it 'returns a 404 and has a missing reservation message' do
      VCR.use_cassette cassette do
        expect(subject.code).to match(404)
        expect(subject.error_message).to match('we can\'t find this reservation')
      end
    end
  end
end
