require 'rails_helper'

RSpec.describe CheckinJob, :type => :job do
  fixtures :reservations, :flights

  let(:flight) { reservations(:denver).flights.where(position: 1).first }

  it 'checks in the flight' do
    VCR.use_cassette 'checkin' do
      perform_enqueued_jobs do
        CheckinJob.perform_later(flight)
      end
    end
  end
end
