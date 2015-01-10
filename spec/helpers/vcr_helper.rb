require 'vcr'
require_relative './sensitive_data_scrubber'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock

  # https://www.relishapp.com/vcr/vcr/v/1-6-0/docs/configuration/hooks#replace-sensitive-data-with-before-record-hook
  c.before_record do |i|
    sensitive_data_scrubber(i.response.body)
  end
end
