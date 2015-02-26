class Checkin < ActiveRecord::Base
  belongs_to :flight
  has_many :passenger_checkins

  validates :flight,
            :scheduled_at,
            presence: true

  def completed?
    completed_at.present?
  end
end
