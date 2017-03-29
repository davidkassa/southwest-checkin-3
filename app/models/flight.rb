class Flight < ActiveRecord::Base
  belongs_to :departure_airport, class_name: 'Airport'
  belongs_to :arrival_airport, class_name: 'Airport'
  belongs_to :reservation, inverse_of: :flights
  has_many :passenger_checkins, dependent: :destroy
  has_one :checkin, dependent: :destroy
  has_one :user, through: :reservation

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

  enum flight_type: { departure: 0, return: 1 }

  def local_departure_time
    Time.use_zone(departure_airport.timezone) do
      departure_time.in_time_zone
    end
  end

  def local_arrival_time
    Time.use_zone(arrival_airport.timezone) do
      arrival_time.in_time_zone
    end
  end

  def scheduled?
    checkin && !checkin.completed?
  end

  def schedule_checkin
    schedule_at = departure_time - 1.day
    job = CheckinJob.set(wait_until: schedule_at).perform_later(self)
    checkin = Checkin.find_or_initialize_by(flight: self)
    checkin.update({
      scheduled_at: schedule_at,
      job_id: job.job_id
    })
  end
end
