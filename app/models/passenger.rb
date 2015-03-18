class Passenger < ActiveRecord::Base
  belongs_to :reservation, inverse_of: :passengers
  validates :reservation, :full_name, presence: true
end
