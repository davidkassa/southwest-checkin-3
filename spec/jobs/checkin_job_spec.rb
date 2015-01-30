require 'rails_helper'

RSpec.describe CheckinJob, :type => :job do
  fixtures :reservations, :flights, :airports

  let(:flight) { reservations(:denver).flights.where(position: 1).first }

  it 'creates a checkin' do
    VCR.use_cassette 'checkin' do
      perform_enqueued_jobs do
        expect { CheckinJob.perform_later(flight) }.to change(Checkin, :count).by(1)
      end
    end
  end

  it 'creates two flight_checkins' do
    pending "this is failing because the associated flight records cannot be found.
      The 'checkin' VCR cassette does not have the corresponding reservation
      records, so a new cassette will be needed for this test"
    VCR.use_cassette 'checkin' do
      perform_enqueued_jobs do
        expect { CheckinJob.perform_later(flight) }.to change(FlightCheckin, :count).by(2)
      end
    end
  end
end
