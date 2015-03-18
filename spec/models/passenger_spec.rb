require 'rails_helper'

RSpec.describe Passenger, :type => :model do
  describe 'creating a passenger' do
    subject { Passenger.create }

    it { should validate_presence_of :reservation }
    it { should validate_presence_of :full_name }

    describe 'with valid attributes' do
      fixtures :reservations, :passengers

      let(:valid_attributes) { { first_name: 'Zip', last_name: 'Baz', full_name: 'Zip Baz' } }

      subject { reservations(:denver).passengers.create(valid_attributes) }

      it 'upcases the confirmation number' do
        expect(subject).to be_valid
      end

      it 'adds the passenger to the reservation' do
        subject
        expect(reservations(:denver).passengers.count).to eql(2)
      end
    end
  end
end
