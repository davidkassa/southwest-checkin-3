require 'rails_helper'

RSpec.describe Checkin, :type => :model do
  fixtures :airports

  it { should validate_presence_of :flight }
  it { should belong_to :flight }
  it { should have_many :passenger_checkins }

  context 'viewAirReservation' do
    let(:cassette) { 'record locator view multi LAX 2016-03-18' }
    let(:reservation) {
      Reservation.create(confirmation_number: "ABC123",
                         first_name: "Fuu",
                         last_name: "Bar")
    }

    context 'on destroy' do
      subject(:checkin) { reservation.checkins.first }

      it 'removes the enqueued checkin jobs if they exist' do
        VCR.use_cassette(cassette) do
          Timecop.freeze(Time.zone.parse('1 Jan 2015')) do
            allow(CheckinJob).to receive(:cancel)

            reservation
            job_id = subject.job_id
            subject.destroy

            expect(CheckinJob).to have_received(:cancel).with(job_id)
          end
        end
      end
    end
  end
end
