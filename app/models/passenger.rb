class Passenger < ActiveRecord::Base
  belongs_to :reservation
end
