class Airport < ActiveRecord::Base
  validates :airport_id, uniqueness: true
end
