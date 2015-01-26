require 'rails_helper'

describe Reservation, :type => :model do
  fixtures :airports

  def recorded(cassette='viewAirReservation')
    VCR.use_cassette(cassette) { yield }
  end

  let(:valid_attributes) {
    {
      confirmation_number: "abc123",
      first_name: "Fuu",
      last_name: "Bar"
    }
  }

  describe 'creating a reservation' do
    describe 'with invalid attributes' do
      subject { Reservation.create }

      it { recorded { should accept_nested_attributes_for :user } }
      it { recorded { should validate_presence_of :first_name } }
      it { recorded { should validate_presence_of :last_name } }
      it { recorded { should validate_presence_of :confirmation_number } }
      it { recorded { should ensure_length_of(:confirmation_number).is_equal_to(6) } }

      it 'sets the arrival_city_name before validation' do
        recorded do
          expect(Reservation.create(valid_attributes).arrival_city_name).to eql('Denver, CO')
        end
      end
    end

    shared_examples 'with valid attributes' do
      subject { Reservation.create(valid_attributes) }
      let(:passenger) { subject.passengers.first }

      it { VCR.use_cassette(cassette) { should be_valid } }

      it 'upcases the confirmation number' do
        VCR.use_cassette(cassette) do
          expect(subject.confirmation_number).to eql('ABC123')
        end
      end

      it 'creates at least one passenger' do
        VCR.use_cassette(cassette) do
          expect(passenger).to be_persisted
          expect(passenger.first_name).to_not be_nil
          expect(passenger.last_name).to_not be_nil
          expect(passenger.full_name).to_not be_nil
        end
      end

      it 'creates at least one passenger' do
        VCR.use_cassette(cassette) do
          expect(passenger).to be_persisted
          expect(passenger.first_name).to_not be_nil
          expect(passenger.last_name).to_not be_nil
          expect(passenger.full_name).to_not be_nil
        end
      end
    end

    context 'viewAirReservation' do
      let(:cassette) { 'viewAirReservation' }

      it_behaves_like 'with valid attributes'

      subject { Reservation.create(valid_attributes) }

      it 'creates two flights' do
        VCR.use_cassette(cassette) do
          expect(subject.flights.count).to eql(2)
        end
      end
    end

    context 'viewAirReservation multi' do
      let(:cassette) { 'viewAirReservation multi' }
      it_behaves_like 'with valid attributes'
    end
  end
end
