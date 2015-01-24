require 'rails_helper'

describe Reservation, :type => :model do
  def recorded
    VCR.use_cassette('viewAirReservation') { yield }
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

    describe 'with valid attributes' do
      subject { Reservation.create(valid_attributes) }

      it { recorded { should be_valid } }

      it 'upcases the confirmation number' do
        recorded do
          expect(Reservation.create(valid_attributes).confirmation_number).to eql('ABC123')
        end
      end

      it 'creates at least one passenger' do
        recorded do
          expect(subject.passengers.first).to be_persisted
        end
      end
    end
  end
end
