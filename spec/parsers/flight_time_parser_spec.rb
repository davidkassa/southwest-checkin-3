require 'rails_helper'

RSpec.describe FlightTimeParser do
  fixtures :airports

  subject { FlightTimeParser.new(city_string: city_string, date_string: date_string) }

  context "06:05 PM Baltimore/Washington, MD (BWI)" do
    let(:city_string) { "06:05 PM Baltimore/Washington, MD (BWI)" }
    let(:date_string) { "Friday, Mar 13, 2015" }

    describe '#utc_datetime' do
      it 'returns the correct UTC datetime' do
        expect(subject.utc_datetime).to eql(DateTime.parse('Fri, 13 Mar 2015 22:05:00 +0000'))
      end
    end

    describe '#city' do
      it 'returns the city string' do
        expect(subject.city).to eql('Baltimore/Washington, MD')
      end
    end

    describe '#city' do
      it 'returns the iata airport code' do
        expect(subject.iata).to eql('BWI')
      end
    end
  end

  context '01:35 PM Chicago (Midway), IL (MDW)' do
    let(:city_string) { "01:35 PM Chicago (Midway), IL (MDW)" }
    let(:date_string) { "Friday, Jan 16, 2015" }

    describe '#utc_datetime' do
      it 'returns the correct UTC datetime' do
        expect(subject.utc_datetime).to eql(DateTime.parse('Fri, 16 Jan 2015 19:35:00 +0000'))
      end
    end

    describe '#city' do
      it 'returns the city string' do
        expect(subject.city).to eql('Chicago (Midway), IL')
      end
    end

    describe '#city' do
      it 'returns the iata airport code' do
        expect(subject.iata).to eql('MDW')
      end
    end
  end

  context 'invalid airport IATA' do
    let(:city_string) { "01:35 PM Chicago (Midway), IL (BAZ)" }
    let(:date_string) { "Friday, Jan 16, 2015" }

    it 'raises ActiveRecord::RecordNotFound' do
      expect { subject.airport }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
