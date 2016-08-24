require 'rails_helper'

RSpec.describe PassengersParser do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }
  let(:cassette) { 'record locator view multi LAX 2016-03-18' }
  let(:response) {
    Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: record_locator)
  }

  subject {
    VCR.use_cassette cassette do
      PassengersParser.new(response.body)
    end
  }

  it 'extracts a single passenger' do
    expect(subject.passengers.count).to eql(1)
  end

  it 'has the required attributes' do
    passenger = subject.passengers.first
    expect(passenger[:first_name]).to eql('FUU')
    expect(passenger[:last_name]).to eql('BAR')
    expect(passenger[:full_name]).to eql('Fuu Bar')
  end
end
