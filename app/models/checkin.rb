class Checkin < ActiveRecord::Base
  belongs_to :flight
  has_many :passenger_checkins, dependent: :destroy

  validates :flight,
            :scheduled_at,
            presence: true

  before_destroy :remove_checkin_job

  def completed?
    completed_at.present?
  end

  def local_scheduled_at
    Time.use_zone(flight.departure_airport.timezone) do
      scheduled_at.in_time_zone
    end
  end

  private

  def remove_checkin_job
    CheckinJob.cancel(job_id) unless completed_at
  end
end
