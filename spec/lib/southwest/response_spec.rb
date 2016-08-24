require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/response'

RSpec.describe Southwest::Response do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  let(:response) {
    Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  context 'invalid JSON body' do
    let(:invalid_json) { "asdfasdf\nasdfasdf\tasdf" }

    it 'returns a string body if JSON parsing fails' do
      VCR.use_cassette 'record locator view multi LAX 2016-03-18' do
        allow_any_instance_of(Typhoeus::Response).to receive(:body) { invalid_json }
        expect(response.body).to eql(invalid_json)
      end
    end
  end

  describe '#to_hash' do
    it 'returns the correct attributes' do
      VCR.use_cassette 'record locator view multi LAX 2016-03-18' do
        expect(response.to_hash).to include(
          :body, :headers, :code, :status_message)
      end
    end
  end
end
