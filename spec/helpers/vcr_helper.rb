require 'vcr'
require_relative './sensitive_data_scrubber'

vcr_confirmation_number = nil
vcr_first_name = nil
vcr_last_name = nil
vcr_flight_numbers = []

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock

  # https://www.relishapp.com/vcr/vcr/v/1-6-0/docs/configuration/hooks#replace-sensitive-data-with-before-record-hook
  c.before_record do |i|
    vcr_confirmation_number ||= get_query_param_value(i.request.body, 'confirmationNumber') || get_query_param_value(i.request.body, 'recordLocator')
    vcr_first_name ||= get_query_param_value(i.request.body, 'confirmationNumberFirstName') || get_query_param_value(i.request.body, 'firstName')
    vcr_last_name ||= get_query_param_value(i.request.body, 'confirmationNumberLastName') || get_query_param_value(i.request.body, 'lastName')
    vcr_flight_numbers += flight_numbers(i.request.body)
    vcr_flight_numbers.uniq
    sensitive_data_scrubber(i.request.body, confirmation_number: vcr_confirmation_number, first_name: vcr_first_name, last_name: vcr_last_name)
    sensitive_data_scrubber(i.response.body, confirmation_number: vcr_confirmation_number, first_name: vcr_first_name, last_name: vcr_last_name)
  end

  c.before_playback(:jan_12_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('01/12/2015')
  }

  c.before_playback(:jan_31_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('01/31/2015')
  }
end

VCR.use_cassette("viewAirReservation", tag: :jan_12_2015) {}
VCR.use_cassette("viewAirReservation_multi", tag: :jan_12_2015) {}
VCR.use_cassette("viewAirReservation_multiple_passengers_mco_pit_nonstop", tag: :jan_31_2015) {}
VCR.use_cassette("viewAirReservation_multiple_passengers_sfo_bwi_1_stop", tag: :jan_31_2015) {}
VCR.use_cassette("viewAirReservation_cancelled", tag: :jan_31_2015) {}
