class FlightCheckin < ActiveRecord::Base
  belongs_to :flight
  belongs_to :checkin

  validates :flight,
            :checkin,
            presence: true
end
