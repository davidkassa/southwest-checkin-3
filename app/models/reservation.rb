class Reservation < ActiveRecord::Base
  has_many :passengers
  accepts_nested_attributes_for :passengers
end
