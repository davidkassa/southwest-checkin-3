require 'rails_helper'

RSpec.describe PassengerCheckin, :type => :model do
  it { should validate_presence_of :flight }
  it { should validate_presence_of :checkin }

  it { should belong_to :flight }
  it { should belong_to :checkin }
end
