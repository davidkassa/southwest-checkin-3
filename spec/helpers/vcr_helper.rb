require 'vcr'
require_relative './sensitive_data_scrubber'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock

  # https://www.relishapp.com/vcr/vcr/v/1-6-0/docs/configuration/hooks#replace-sensitive-data-with-before-record-hook
  c.before_record do |i|
    sensitive_data_scrubber(i.request.body)
    sensitive_data_scrubber(i.response.body)
  end

  c.before_playback(:jan_12_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('01/12/2015')
  }
end

VCR.use_cassette("viewAirReservation", tag: :jan_12_2015) {}
VCR.use_cassette("viewAirReservation_multi", tag: :jan_12_2015) {}
