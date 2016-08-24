require 'vcr'
require_relative './sensitive_data_scrubber'

scrubber = SensitiveDataScrubber.new

vcr_confirmation_number = nil
vcr_first_name = nil
vcr_last_name = nil
vcr_flight_numbers = []

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock

  # https://www.relishapp.com/vcr/vcr/v/1-6-0/docs/configuration/hooks#replace-sensitive-data-with-before-record-hook
  c.before_record do |i|
    scrubber.setup(i.request.body, i.response.body)
    scrubber.scrub!(i.request.body)
    scrubber.scrub!(i.response.body)
  end
end
