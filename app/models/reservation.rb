class Reservation < ActiveRecord::Base
  belongs_to :user
  has_many :passengers, inverse_of: :reservation
  accepts_nested_attributes_for :user

  before_validation :retrieve_reservation, on: :create
  before_save :upcase_confirmation_number

  validates_associated :passengers
  # validates :passengers, length: { minimum: 1 }
  validates :confirmation_number, :first_name, :last_name, :arrival_city_name, presence: true
  validates :confirmation_number, length: { is: 6 }

  private

  def upcase_confirmation_number
    self.confirmation_number = self.confirmation_number.upcase
  end

  def retrieve_reservation
    self.arrival_city_name = southwest_reservation[:reservation]["upComingInfo"][0]["arrivalCityName"]
    # passengers.first.full_name = southwest_reservation[:reservation]["upComingInfo"][0]["passengerName0"]
  end

  def southwest_reservation
    @southwest_reservation ||= Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: confirmation_number
    )
  end
end
