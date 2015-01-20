class Reservation < ActiveRecord::Base
  has_many :passengers
  belongs_to :user
  accepts_nested_attributes_for :passengers, :user
end
