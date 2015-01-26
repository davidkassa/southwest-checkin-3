class Flight < ActiveRecord::Base
  belongs_to :departure_airport, class_name: 'Airport'
  belongs_to :arrival_airport, class_name: 'Airport'
  belongs_to :reservation, inverse_of: :flights
  validates :departure_time,
            :arrival_time,
            :departure_city,
            :arrival_city,
            :payload,
            :departure_airport,
            :arrival_airport,
            :reservation,
            :position,
            :flight_type,
            presence: true

  enum flight_type: { departure: 0, 'return': 1 }
end
