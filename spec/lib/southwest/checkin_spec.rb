require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/checkin'

RSpec.describe Southwest::Checkin do
  let(:cassette) { 'record locator checkin LAX 2016-03-18' }
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  subject(:checkin) {
    Southwest::Checkin.new(
      names: [{
        last_name: last_name,
        first_name: first_name,
      }],
      record_locator: record_locator
    )
  }

  describe '.checkin' do
    it 'standard flight' do
      VCR.use_cassette cassette do
        expect(subject.checkin.body).to match_json_schema(:record_locator_boarding_passes)
      end
    end

    describe 'multi-passenger domestic' do
      let(:cassette) { '2016-11-28 multi-passenger checkin mci' }

      subject(:checkin) {
        Southwest::Checkin.new(
          names: [{
            last_name: 'Bar',
            first_name: 'Fuu',
          }, {
            last_name: 'Bar',
            first_name: 'Qix',
          }],
          record_locator: 'ABC123'
        )
      }

      it 'matches the json schema' do
        VCR.use_cassette cassette do
          expect(subject.checkin.body).to match_json_schema(:record_locator_boarding_passes)
        end
      end

      it 'contains both passengers on the reservation' do
        VCR.use_cassette cassette do
          expect(subject.checkin.body['passengerCheckInDocuments'].count).to eq(2)
        end
      end
    end

    it 'international multi passenger' do
      VCR.use_cassette 'international multi passenger 2016-07-09' do
        expect(subject.checkin.body).to match_json_schema(:record_locator_boarding_passes)
      end
    end

    it 'international single passenger' do
      VCR.use_cassette 'international single passenger 2016-07-09' do
        expect(subject.checkin.body).to match_json_schema(:record_locator_boarding_passes)
      end
    end
  end

  describe '.email_boarding_passes' do
    it 'sends an email' do
      VCR.use_cassette 'record locator email boarding passes LAX 2016-03-18' do
        response = subject.email_boarding_passes('fuu.bar@example.com')
        expect(response.body['notifications'][0]['status']).to eql('SUCCESS')
      end
    end
  end
end
