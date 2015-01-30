require 'rails_helper'

RSpec.describe Flight, :type => :model do
  it { should validate_presence_of :departure_time }
  it { should validate_presence_of :arrival_time }
  it { should validate_presence_of :departure_city }
  it { should validate_presence_of :arrival_city }
  it { should validate_presence_of :payload }
  it { should validate_presence_of :flight_type }
  it { should validate_presence_of :position }
  it { should validate_presence_of :reservation }
  it { should validate_presence_of :departure_airport }
  it { should validate_presence_of :arrival_airport }

  it { should belong_to :reservation }
  it { should belong_to :departure_airport }
  it { should belong_to :arrival_airport }
  it { should have_one :flight_checkin }

  it { should define_enum_for(:flight_type).with(%w{departure return}) }
end
