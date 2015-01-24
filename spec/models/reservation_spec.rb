require 'rails_helper'

describe Reservation, :type => :model do
  describe 'creating a reservation' do
    describe 'with invalid attributes' do
      subject { Reservation.create }

      it { should accept_nested_attributes_for :passengers }
      it { should accept_nested_attributes_for :user }

      it { should validate_presence_of :confirmation_number }
      it { should ensure_length_of(:confirmation_number).is_equal_to(6) }
      it { should validate_presence_of :arrival_city_name }

      it 'must include at least one passenger' do
        expect(Reservation.create({
          confirmation_number: "ABC123",
        }).errors[:passengers]).to include(
          "is too short (minimum is 1 character)")
      end
    end

    describe 'with valid attributes' do
      let(:valid_attributes) {
        {
          confirmation_number: "abc123",
          arrival_city_name: "10:05 PM Denver, CO (DEN)",
          passengers_attributes: [{
            first_name: "Fuu",
            last_name: "Bar",
            full_name: "Fuu Bar"
          }]
        }
      }

      it 'upcases the confirmation number' do
        VCR.use_cassette 'viewAirReservation' do
          expect(Reservation.create(valid_attributes).confirmation_number).to eql('ABC123')
        end
      end
    end
  end
end
