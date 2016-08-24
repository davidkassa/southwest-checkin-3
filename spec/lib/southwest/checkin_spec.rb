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
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  describe '.checkin' do
    it 'matches the JSON schema for boarding passes' do
      VCR.use_cassette cassette do
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
