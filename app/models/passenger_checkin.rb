class PassengerCheckin < ActiveRecord::Base
  belongs_to :flight
  belongs_to :checkin
  belongs_to :passenger

  validates :flight,
            :checkin,
            :passenger,
            presence: true
end
