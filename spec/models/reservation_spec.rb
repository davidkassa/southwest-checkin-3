require 'rails_helper'

describe Reservation, :type => :model do
  describe 'creating a reservation' do
    describe 'with invalid attributes' do
      it 'must have a valid confirmation_number' do
        expect(Reservation.create({
          arrival_city_name: "10:05 PM Denver, CO (DEN)",
        }).errors[:confirmation_number]).to include(
          "can't be blank",
          "is the wrong length (should be 6 characters)")
      end

      it 'must include an arrival_city_name' do
        expect(Reservation.create({
          confirmation_number: "ABC123",
        }).errors[:arrival_city_name]).to include(
          "can't be blank")
      end

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
        expect(Reservation.create(valid_attributes).confirmation_number).to eql('ABC123')
      end
    end
  end
end
