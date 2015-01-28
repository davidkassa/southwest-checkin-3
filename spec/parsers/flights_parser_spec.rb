require 'rails_helper'

RSpec.describe FlightsParser do
  fixtures :reservations, :airports

  shared_examples_for 'FlightParser' do
    describe '#flights' do
      describe 'each flight' do
        let(:expected_keys) {
          [
            :departure_time,
            :arrival_time,
            :departure_city,
            :arrival_city,
            :departure_airport,
            :arrival_airport,
            :flight_type,
            :position,
            :payload
          ]
        }

        it 'returns a value for all attributes' do
          subject.flights.each do |flight|
            expected_keys.each do |key|
              expect(flight[key]).to_not be_nil
            end
          end
        end
      end
    end
  end

  context 'New Orleans Reservation' do
    subject { FlightsParser.new(reservations(:new_orleans).payload["body"]) }

    it_behaves_like 'FlightParser'

    it 'returns departure and return flights' do
      expect(subject.flights.count).to eql(3)
    end

    describe '#departure_flights' do
      it 'returns a single departure flight' do
        expect(subject.departure_flights.count).to eql(1)
      end
    end

    describe '#return_flights' do
      it 'returns two return flights' do
        expect(subject.return_flights.count).to eql(2)
      end
    end
  end

  context 'Denver Reservation' do
    subject { FlightsParser.new(reservations(:denver).payload["body"]) }

    it_behaves_like 'FlightParser'

    describe '#flights' do
      it 'returns departure and return flights' do
        expect(subject.flights.count).to eql(2)
      end
    end

    describe 'first flight' do
      let(:first) { subject.flights.first }

      it 'corresponds to a 2h15m flight' do
        expect(first[:arrival_time].to_i - first[:departure_time].to_i).to eql((2.hour + 15.minutes).to_i)
      end

      it 'has the correct `:flight_type` enum' do
        expect(first[:flight_type]).to eql(0)
      end

      it 'has the correct UTC departure time' do
        expect(first[:departure_time]).to eql(Time.zone.parse('2015-01-17 02:10:00').to_datetime)
      end

      it 'has the correct UTC arrival time' do
        expect(first[:arrival_time]).to eql(Time.zone.parse('2015-01-17 04:25:00').to_datetime)
      end
    end

    describe 'second flight' do
      let(:second) { subject.flights.second }

      it 'has the correct UTC departure time' do
        expect(second[:departure_time]).to eql(Time.zone.parse('2015-01-17 05:05:00').to_datetime)
      end

      it 'has the correct UTC arrival time' do
        expect(second[:arrival_time]).to eql(Time.zone.parse('2015-01-17 06:25:00').to_datetime)
      end
    end
  end

  context 'a flight spanning two days' do
    it 'returns the next day for the arrival time' do
      json = reservations(:new_orleans).payload["body"]
      json["upComingInfo"][0]["Return2"]["arrivalCity"] = "01:00 AM Baltimore/Washington, MD (BWI)"

      expect(FlightsParser.new(json).return_flights.last[:arrival_time]).to eql(DateTime.parse("18 Mar 2015 05:00:00 +0000"))
    end
  end
end
