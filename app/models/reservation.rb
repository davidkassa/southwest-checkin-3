class Reservation < ActiveRecord::Base
  belongs_to :user
  has_many :passengers, inverse_of: :reservation, autosave: true
  accepts_nested_attributes_for :user

  before_validation :retrieve_reservation, on: :create
  before_create :create_passengers
  before_save :upcase_confirmation_number

  validates_associated :passengers
  validates :confirmation_number, :first_name, :last_name, :arrival_city_name, :payload, presence: true
  validates :confirmation_number, length: { is: 6 }

  private

  def upcase_confirmation_number
    self.confirmation_number = self.confirmation_number.upcase
  end

  def retrieve_reservation
    self.payload = southwest_reservation.to_hash
    self.arrival_city_name = southwest_reservation.body["upComingInfo"][0]["arrivalCityName"]
  end

  def create_passengers
    passengers_attributes = PassengersParser.new(southwest_reservation.body).passengers

    passengers_attributes.each do |passenger_attributes|
      passengers.new(passenger_attributes)
    end
  end

  def southwest_reservation
    @southwest_reservation ||= Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: confirmation_number
    )
  end
end
