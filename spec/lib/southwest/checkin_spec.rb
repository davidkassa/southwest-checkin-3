require 'spec_helper'
require 'helpers/vcr_helper'
require_relative '../../../lib/southwest/checkin'

RSpec.describe Southwest::Checkin do
  let(:last_name) { 'Bar' }
  let(:first_name) { 'Fuu' }
  let(:record_locator) { 'ABC123' }

  describe 'instance methods' do
    subject(:checkin) {
      Southwest::Checkin.new(
        last_name: last_name,
        first_name: first_name,
        record_locator: record_locator)
    }

    describe 'HTTP requests initialize a session' do
      let(:jsessionid) { '4A508841E779EB7E959D22737087FAE5' }
      let(:cacheid) { '124f9430192-ab08-4426-884d-1a38f231e349' }

      describe '#get_travel_info' do
        before do
          VCR.use_cassette 'getTravelInfo' do
            subject.send :get_travel_info
          end
        end

        it 'sets @jsessionid from cookie' do
          expect(subject.jsessionid).to eql(jsessionid)
        end

        it 'sets @cacheid from cookie' do
          expect(subject.cacheid).to eql(cacheid)
        end
      end
    end

    describe '#check_intravel_alerts' do
      it 'returns a green app state' do
        VCR.use_cassette 'checkIntravelAlerts' do
          expect(JSON.parse(subject.send(:check_intravel_alerts).body)['appState']).to eql('green')
        end
      end
    end
  end

  describe '.checkin' do
    subject(:checkin) {
      Southwest::Checkin.checkin(
        last_name: last_name,
        first_name: first_name,
        record_locator: record_locator)
    }

    shared_examples_for 'successful checkin' do
      let(:expected_flight_information_keys) {
        ["arrivalCityCode", "stop1", "changeplaneImage", "departRouting", "wifiInfo", "departTime", "flightOperator", "departCityCode", "seperatorflag", "departCity", "stopmsg", "travelDate", "flightNumber", "date", "arrivalCityName", "arrivalTime", "traveltime", "scheduleDepart", "stop3", "stop2", "arriveCity"]
      }

      let(:expected_single_passenger_details_keys) {
        ['mbpDepartDate', 'departCode', 'pass_rr_number', 'itineraryHeader', 'mbp_confirmationNumber', 'mbp_tier_status', 'mbprouting', 'arriveCode', 'departCity', 'mbpDepartTime', 'mbp_gateValue', 'itineraryRouting', 'arriveCity']
      }

      let(:expected_check_in_details_keys) {
        ["flight_num", "name", "pnr", "boardingroup_text", "position1_text"]
      }

      it '#flight_checkin_new returns a valid Southwest::Response' do
        VCR.use_cassette cassette do
          expect(subject.flight_checkin_new.code).to eql(200)
        end
      end

      it '#get_all_boarding_passes returns a valid Southwest::Response' do
        VCR.use_cassette cassette do
          expect(subject.get_all_boarding_passes.code).to eql(200)
        end
      end

      it '#view_boarding_passes returns a valid Southwest::Response' do
        VCR.use_cassette cassette do
          expect(subject.view_boarding_passes.code).to eql(200)
        end
      end

      it 'must return at least one flight from #flight_information' do
        VCR.use_cassette cassette do
          expect(subject.flight_information.count).to be > 0
        end
      end

      it '#flight_information returns the correct keys' do
        VCR.use_cassette cassette do
          subject.flight_information.each do |flight|
            expect(flight).to include(*expected_flight_information_keys)
          end
        end
      end

      it 'must return boarding pass documents or details' do
        VCR.use_cassette cassette do
          total = subject.multiple_passenger_documents.count + subject.single_passenger_details.count
          expect(total).to be > 0
        end
      end

      describe '#multiple_passenger_documents' do
        let(:expected_checkin_document_keys) { ["documentType", "docType", "boardingroup_sec", "routing", "flight_operator", "flight_num", "boadingPassNotIssuedSeatMsg", "name", "boardingroupsec_text", "at_return_time", "flightOperatorDocDescription", "boardingroup_text", "position_1_sec", "position2sec_text", "dep_date", "position_2", "position2_text", "at_seat", "position_1", "boardingroup", "pnr", "at_depart_time", "position1_text", "boardingPassNotIssued", "at_return_station", "position_2_sec", "at_gate", "route", "at_depart_station", "secDocText", "position1sec_text", "cntFltNo", "at_zone"] }

        it 'returns the correct checkin document keys' do
          VCR.use_cassette cassette do
            subject.multiple_passenger_documents.each do |doc|
              expect(doc).to include(*expected_checkin_document_keys)
            end
          end
        end
      end


      it 'boarding pass details contain the correct data' do
        VCR.use_cassette cassette do
          subject.single_passenger_details.each do |flight|
            expect(flight).to include(*expected_single_passenger_details_keys)
          end
        end
      end

      it 'checkin details contain the correct data' do
        VCR.use_cassette cassette do
          subject.single_passenger_documents.each do |flight|
            expect(flight).to include(*expected_check_in_details_keys)
          end
        end
      end
    end

    # This currently fails because of changes to #checkin that makes less
    # requests than it did before.
    pending 'checkin cassette' do
      let(:cassette) { 'checkin' }
      it_behaves_like 'successful checkin'
    end

    context 'multiple passengers on a reservation - SFO to BWI, 1 Stop' do
      let(:cassette) { 'checkin multiple passengers sfo bwi 1 stop' }

      it_behaves_like 'successful checkin'
    end

    context 'multiple passengers on a reservation - MCO to PIT, nonstop' do
      let(:cassette) { 'checkin multiple passengers mco pit nonstop' }

      it_behaves_like 'successful checkin'
    end

    context 'single passenger - BWI to BOS, nonstop' do
      let(:cassette) { 'checkin single passenger bwi bos nonstop' }

      it_behaves_like 'successful checkin'
    end

    context 'single MDW MCI' do
      let(:cassette) { 'checkin single MDW MCI' }

      it_behaves_like 'successful checkin'
    end

    context 'checkin non matching confirmation' do
      it 'returns a CheckinErrorResponse' do
        VCR.use_cassette 'checkin non matching confirmation' do
          expect(subject).to be_a(Southwest::CheckinErrorResponse)
        end
      end
    end

    context 'checkin too early' do
      it 'returns a CheckinErrorResponse' do
        VCR.use_cassette 'checkin too early' do
          expect(subject).to be_a(Southwest::CheckinErrorResponse)
        end
      end

      it 'contains the error message' do
        VCR.use_cassette 'checkin too early' do
          expect(subject.error).to match(/The request to check in and print your Boarding Pass is more than 24 hours prior to your scheduled departure or less than 1 hour prior to departure flight time/)
        end
      end
    end

    context 'cancelled reservation' do
      it 'returns a CheckinErrorResponse' do
        VCR.use_cassette 'checkin cancelled reservation' do
          expect(subject).to be_a(Southwest::CheckinErrorResponse)
        end
      end

      it 'contains the error message' do
        VCR.use_cassette 'checkin cancelled reservation' do
          expect(subject.error).to match(/Your reservation has been cancelled./)
        end
      end

      describe 'Southwest::CheckinErrorResponse#cancelled_reservation?' do
        it 'returns true' do
          VCR.use_cassette 'checkin cancelled reservation' do
            expect(subject.cancelled_reservation?).to be true
          end
        end
      end
    end

    context 'missing flight information' do
      it 'returns a CheckinErrorResponse' do
        VCR.use_cassette 'checkin single MDW MCI missing flight information' do
          expect(subject).to be_a(Southwest::CheckinErrorResponse)
        end
      end

      it 'contains the error message' do
        VCR.use_cassette 'checkin single MDW MCI missing flight information' do
          expect(subject.error).to eql("The request to 'flight_checkin_new' was successful, however the response had missing flight information. Check the response for more detail.")
        end
      end
    end

    context 'missing boarding pass information' do
      it 'returns a CheckinErrorResponse' do
        VCR.use_cassette 'checkin single MDW MCI missing boarding pass information' do
          expect(subject).to be_a(Southwest::CheckinErrorResponse)
        end
      end

      it 'contains the error message' do
        VCR.use_cassette 'checkin single MDW MCI missing boarding pass information' do
          expect(subject.error).to eql("The request to 'getallboardingpass' was successful, however the response had missing boarding pass information. Check the response for more detail.")
        end
      end
    end
  end
end
