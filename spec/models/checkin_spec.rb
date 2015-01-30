require 'rails_helper'

RSpec.describe Checkin, :type => :model do
  it { should validate_presence_of :reservation }
  it { should validate_presence_of :payload }
  it { should belong_to :reservation }
  it { should have_many :flight_checkins }
  it { should have_many :flights }
end
