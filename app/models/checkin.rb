class Checkin < ActiveRecord::Base
  belongs_to :flight
  has_many :passenger_checkins

  validates :flight,
            :scheduled_at,
            presence: true

  def completed?
    completed_at.present?
  end

  def local_scheduled_at
    Time.use_zone(flight.departure_airport.timezone) do
      scheduled_at.in_time_zone
    end
  end
end
