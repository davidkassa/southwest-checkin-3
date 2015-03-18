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

  c.before_playback(:jan_12_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('01/12/2015')
  }

  c.before_playback(:jan_31_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('01/31/2015')
  }

  c.before_playback(:feb_08_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('02/08/2015')
  }

  c.before_playback(:mar_11_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('03/11/2015')
  }

  c.before_playback(:mar_17_2015) {
    allow_any_instance_of(Southwest::Reservation).to receive(:todays_date_formatted).and_return('03/17/2015')
  }
end

VCR.use_cassette("viewAirReservation", tag: :jan_12_2015) {}
VCR.use_cassette("viewAirReservation_multi", tag: :jan_12_2015) {}
VCR.use_cassette("viewAirReservation_multiple_passengers_mco_pit_nonstop", tag: :jan_31_2015) {}
VCR.use_cassette("viewAirReservation_multiple_passengers_sfo_bwi_1_stop", tag: :jan_31_2015) {}
VCR.use_cassette("viewAirReservation_cancelled", tag: :jan_31_2015) {}
VCR.use_cassette("viewAirReservation_single_MDW_MCI", tag: :feb_08_2015) {}
VCR.use_cassette("bad_reservation_information", tag: :mar_11_2015) {}
VCR.use_cassette("viewAirReservation_with_next_day_flight", tag: :mar_17_2015) {}
