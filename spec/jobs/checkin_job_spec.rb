require 'rails_helper'

RSpec.describe CheckinJob, :type => :job do
  fixtures :airports, :reservations, :flights

  shared_context 'setup existing reservation' do
    let(:reservation) {
      Reservation.create({
        confirmation_number: "ABC123",
        first_name: "Fuu",
        last_name: "Bar"
      })
    }
    let(:flight) { reservation.flights.where(position: 1).first }
    let(:passenger_checkins) { flight.checkin.reload.passenger_checkins }

    # Flight checkins are not scheduled unless they are in the future
    let(:before_all_departure_times) { Time.zone.parse('1 Jan 2015') }

    before do
      VCR.use_cassette reservation_cassette do
        Timecop.freeze(before_all_departure_times) do
          reservation
        end
      end
    end
  end

  def perform
    VCR.use_cassette checkin_cassette do
      perform_enqueued_jobs do
        yield
      end
    end
  end

  context 'single passenger' do
    let(:reservation_cassette) { 'record locator view multi LAX 2016-03-18' }
    let(:checkin_cassette) { 'record locator checkin and email LAX 2016-03-18' }
    let(:ordered_passenger_names) { passenger_checkins.includes(:passenger).map { |c| c.passenger.full_name } }

    include_context 'setup existing reservation'

    it 'updates the checkin' do
      perform do
        CheckinJob.perform_later(flight)
        expect(flight.checkin.payload).to_not be_nil
        expect(flight.checkin.completed_at).to_not be_nil
      end
    end

    it 'creates 1 flight checkin per flight' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to change(PassengerCheckin, :count).by(1)
      end
    end

    it 'passenger_checkins have the correct passengers' do
      perform do
        CheckinJob.perform_later(flight)
        expect(ordered_passenger_names).to eql([
          'Fuu Bar',
        ])
      end
    end

    context 'the reservation has a user' do
      let(:user) { User.create(email: 'fuu.bar@baz.com', password: 'password') }

      before do
        reservation.user_id = user.id
        reservation.save!
      end

      it "sends a checkin email to the reservation's user" do
        perform do
          CheckinJob.perform_later(flight)
          email = ActionMailer::Base.deliveries.first
          expect(email.to).to eql(['fuu.bar@baz.com'])
          expect(email.subject).to eql("#ABC123 - Flight #1001 - Successful Checkin")
          expect(email.from).to eql('test@localhost:3000')
          expect(email.reply_to).to eql('test@localhost:3000')
        end
      end
    end
  end

  context 'incorrect passenger information' do
    let(:reservation_cassette) { 'viewAirReservation single MDW MCI' }
    let(:checkin_cassette) { 'checkin non matching confirmation' }

    include_context 'setup existing reservation'

    skip 'should not raise an error' do
      perform do
        expect { CheckinJob.perform_later(flight) }.not_to raise_error
      end
    end

    skip 'should add the error to the record and mark it completed' do
      perform do
        CheckinJob.perform_later(flight)
        expect(reservation.checkins.first.error).to match /passenger name entered does not match/
        expect(reservation.checkins.first.completed_at).not_to be nil
      end
    end
  end

  context 'international flight' do
    let(:reservation_cassette) { 'international 2016-07-08' }
    let(:checkin_cassette) { 'international multi passenger 2016-07-09' }

    include_context 'setup existing reservation'

    it 'checks in' do
      perform do
        CheckinJob.perform_later(flight)
        expect(flight.checkin.payload).to_not be_nil
        expect(flight.checkin.completed_at).to_not be_nil
      end
    end
  end
end
