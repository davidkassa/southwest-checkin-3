require 'rails_helper'

RSpec.describe Reservation, type: :model do
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
    it 'sets the arrival_city_name before validation' do
      recorded do
        expect(Reservation.create(valid_attributes).arrival_city_name).to eql('Denver, CO')
      end
    end

    describe 'with invalid attributes' do
      subject { Reservation.create }
      let(:invalid_attributes) {
        {
          confirmation_number: "abc123",
          first_name: "Fuu",
          last_name: "Bar"
        }
      }

      it { recorded { should accept_nested_attributes_for :user } }
      it { recorded { should validate_presence_of :first_name } }
      it { recorded { should validate_presence_of :last_name } }
      it { recorded { should validate_presence_of :confirmation_number } }
      it { recorded { should ensure_length_of(:confirmation_number).is_equal_to(6) } }

      context 'bad reservation information' do
        let(:cassette) { 'bad reservation information' }

        subject { Reservation.create(invalid_attributes) }

        it 'raise a validation error' do
          VCR.use_cassette(cassette) do
            expect(subject.valid?).to eql(false)
            expect(subject.errors[:confirmation_number]).to eql ['verify your confirmation number is entered correctly']
            expect(subject.errors[:first_name]).to eql ['verify your first name is entered correctly']
            expect(subject.errors[:last_name]).to eql ['verify your last name is entered correctly']
          end
        end
      end

      context 'viewAirReservation cancelled' do
        let(:cassette) { 'viewAirReservation cancelled' }

        subject { Reservation.create(invalid_attributes) }

        it 'raise a validation error' do
          VCR.use_cassette(cassette) do
            expect(subject.errors[:base].first).to match /Your reservation has been cancelled/
          end
        end
      end
    end

    context 'international flight' do
      let(:cassette) { 'international flight Punta Cana DO' }
      subject { Reservation.create(valid_attributes) }

      it "does not allow international flights (until they are supported)" do
        VCR.use_cassette(cassette) do
          expect(subject.valid?).to eql(false)
          expect(subject.errors[:base].first).to match /international flights are not yet supported/
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

      it 'each passenger has a full name' do
        VCR.use_cassette(cassette) do
          subject.passengers.each do |passenger|
            expect(passenger.full_name).to_not be_nil
          end
        end
      end

      it 'each flight has a flight number' do
        VCR.use_cassette(cassette) do
          subject.flights.each do |flight|
            expect(flight.flight_number).to_not be_nil
          end
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

      it 'schedules 1 checkin for the first departure flight' do
        VCR.use_cassette(cassette) do
          Timecop.freeze(Time.zone.parse('1 Jan 2015')) do
            subject
            expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq(1)
          end
        end
      end

      it 'enqueues the checkin 23hr59m59s before departure' do
        VCR.use_cassette(cassette) do
          Timecop.freeze(Time.zone.parse('1 Jan 2015')) do
            subject
            enqueued_at = Time.zone.at(ActiveJob::Base.queue_adapter.enqueued_jobs.first[:at])
            expect(enqueued_at).to eq(Time.zone.parse("Fri, 16 Jan 2015 02:10:01 UTC +00:00"))
          end
        end
      end

      it 'does not enqueue flights in the past' do
        VCR.use_cassette(cassette) do
          subject
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq(0)
        end
      end
    end

    context 'viewAirReservation multi' do
      let(:cassette) { 'viewAirReservation multi' }
      it_behaves_like 'with valid attributes'
    end

    context 'multiple passengers MCO PIT nonstop' do
      let(:cassette) { "viewAirReservation_multiple_passengers_mco_pit_nonstop" }

      subject { Reservation.create(valid_attributes) }

      it_behaves_like 'with valid attributes'

      it 'creates three passengers' do
        VCR.use_cassette(cassette) do
          expect(subject.passengers.count).to eql(3)
        end
      end
    end

    context 'viewAirReservation multiple passengers sfo bwi 1 stop' do
      let(:cassette) { "viewAirReservation multiple passengers sfo bwi 1 stop" }

      subject { Reservation.create(valid_attributes) }

      it_behaves_like 'with valid attributes'

      it 'creates two passengers' do
        VCR.use_cassette(cassette) do
          expect(subject.passengers.count).to eql(2)
        end
      end
    end

    context 'viewAirReservation with next day flight' do
      let(:cassette) { 'viewAirReservation with next day flight' }
      subject { Reservation.create(valid_attributes) }

      it_behaves_like 'with valid attributes'
    end
  end

  describe 'destroying a reservation that has been checked in' do
    let(:reservation_cassette) { 'viewAirReservation multiple passengers sfo bwi 1 stop' }
    let(:checkin_cassette) { 'checkin multiple passengers sfo bwi 1 stop' }
    let(:reservation) {
      Reservation.create({
        confirmation_number: "ABC123",
        first_name: "Fuu",
        last_name: "Bar"
      })
    }
    let(:flight) { reservation.flights.where(position: 1).first }

    # Flight checkins are not scheduled unless they are in the future
    let(:before_all_departure_times) { Time.zone.parse('1 Jan 2015') }

    before do
      VCR.use_cassette reservation_cassette do
        Timecop.freeze(before_all_departure_times) do
          reservation
        end
      end

      VCR.use_cassette checkin_cassette do
        perform_enqueued_jobs do
          CheckinJob.perform_later(flight)
        end
      end
    end

    it 'creates 4 flight checkins' do
      expect { reservation.destroy }.to_not raise_error
    end
  end
end
