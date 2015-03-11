class ReservationMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  def new_reservation(reservation, email)
    @reservation = reservation
    @email = email
    mail(to: @email, subject: "#{reservation.confirmation_number} - #{ENV['SITE_NAME']}")
  end
end
