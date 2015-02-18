class Reservation < ActiveRecord::Base
  belongs_to :user
  has_many :passengers, inverse_of: :reservation, autosave: true
  has_many :flights, inverse_of: :reservation, autosave: true
  has_one :checkin
  accepts_nested_attributes_for :user

  before_validation :retrieve_reservation, on: :create
  before_create :create_passengers
  before_create :create_flights
  before_save :upcase_confirmation_number
  after_save :schedule_checkins

  validates_associated :passengers
  validates :confirmation_number, length: { is: 6 }
  validates :confirmation_number,
            :first_name,
            :last_name,
            :arrival_city_name,
            :payload,
            presence: true

  def departure_flights
    flights.departure.order(:departure_time)
  end

  def return_flights
    flights.return.order(:departure_time)
  end

  def time
    departure_flights.first.departure_time
  end

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

  def create_flights
    flights_attributes = FlightsParser.new(southwest_reservation.body).flights

    flights_attributes.each do |flight_attributes|
      flights.new(flight_attributes)
    end
  end

  def southwest_reservation
    @southwest_reservation ||= Southwest::Reservation.retrieve_reservation(
      last_name: last_name,
      first_name: first_name,
      record_locator: confirmation_number
    )
  end

  def schedule_checkins
    flights.where(position: 1).where("departure_time > ?", Time.zone.now).each do |flight|
      CheckinJob.set(wait_until: flight.departure_time - 1.day + 1.second).perform_later(flight)
    end
  end
end
