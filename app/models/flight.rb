class Flight < ActiveRecord::Base
  belongs_to :departure_airport, class_name: 'Airport'
  belongs_to :arrival_airport, class_name: 'Airport'
  belongs_to :reservation
  validates :departure_time,
            :arrival_time,
            :departure_city,
            :arrival_city,
            :payload,
            :departure_airport,
            :arrival_airport,
            :reservation,
            presence: true
end
