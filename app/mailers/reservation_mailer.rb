class ReservationMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  def new_reservation(reservation)
    @reservation = reservation
    @email = reservation.user.email
    mail(to: @email, subject: "##{reservation.confirmation_number} - #{flight_header(reservation)} - #{ENV['SITE_NAME']}")
  end

  private

  def flight_header(reservation)
    flights = []
    if reservation.departure_flights.any?
      flights << "#{reservation.departure_flights.first.departure_airport.iata} -> #{reservation.departure_flights.last.arrival_airport.iata}"
    end
    if reservation.return_flights.any?
      flights << "#{reservation.return_flights.first.departure_airport.iata} -> #{reservation.return_flights.last.arrival_airport.iata}"
    end
    flights.join(' · ')
  end
end
