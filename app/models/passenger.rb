class Passenger < ActiveRecord::Base
  belongs_to :reservation, inverse_of: :passengers
  has_many :passenger_checkins, dependent: :destroy

  validates :reservation, :full_name, presence: true
end
