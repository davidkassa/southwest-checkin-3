class Checkin < ActiveRecord::Base
  belongs_to :reservation
  has_many :flight_checkins
  has_many :flights, through: :flight_checkins

  validates :reservation,
            :payload,
            presence: true
end
