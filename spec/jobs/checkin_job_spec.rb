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
    let(:flight_checkins) { reservation.checkin.reload.flight_checkins }

    before do
      VCR.use_cassette reservation_cassette do
        reservation
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
    let(:reservation_cassette) { 'viewAirReservation single MDW MCI' }
    let(:checkin_cassette) { 'checkin single MDW MCI' }

    include_context 'setup existing reservation'

    it 'creates a checkin' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to change(Checkin, :count).by(1)
      end
    end

    it 'creates 1 flight checkin' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to change(FlightCheckin, :count).by(1)
      end
    end
  end

  context 'checkin multiple passengers sfo bwi 1 stop' do
    let(:reservation_cassette) { 'viewAirReservation multiple passengers sfo bwi 1 stop' }
    let(:checkin_cassette) { 'checkin multiple passengers sfo bwi 1 stop' }
    let(:ordered_passenger_names) { flight_checkins.includes(:passenger).map { |c| c.passenger.full_name } }

    include_context 'setup existing reservation'

    it 'creates a checkin' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to change(Checkin, :count).by(1)
      end
    end

    it 'creates 4 flight checkins' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to change(FlightCheckin, :count).by(4)
      end
    end

    it 'flight_checkins have the correct passengers' do
      perform do
        CheckinJob.perform_later(flight)
        expect(ordered_passenger_names).to eql([
          'Fuu Bar',
          'Fuu Bar',
          'John Smith',
          'John Smith'
        ])
      end
    end
  end

  context 'missing flight information' do
    let(:reservation_cassette) { 'viewAirReservation single MDW MCI' }
    let(:checkin_cassette) { 'checkin single MDW MCI missing flight information' }

    include_context 'setup existing reservation'

    it 'should raise SouthwestCheckin::FailedCheckin' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to raise_error(SouthwestCheckin::FailedCheckin)
      end
    end
  end

  context 'missing boarding pass information' do
    let(:reservation_cassette) { 'viewAirReservation single MDW MCI' }
    let(:checkin_cassette) { 'checkin single MDW MCI missing boarding pass information' }

    include_context 'setup existing reservation'

    it 'should raise SouthwestCheckin::FailedCheckin' do
      perform do
        expect { CheckinJob.perform_later(flight) }.to raise_error(SouthwestCheckin::FailedCheckin)
      end
    end
  end
end
