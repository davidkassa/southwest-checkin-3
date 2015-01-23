class Passenger < ActiveRecord::Base
  belongs_to :reservation, inverse_of: :passengers
  validates :reservation, :first_name, :last_name, :full_name, presence: true
end
