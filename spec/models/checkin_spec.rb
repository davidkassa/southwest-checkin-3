require 'rails_helper'

RSpec.describe Checkin, :type => :model do
  it { should validate_presence_of :flight }
  it { should belong_to :flight }
  it { should have_many :passenger_checkins }
end
