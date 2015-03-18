class CheckinMailer < ApplicationMailer
  include Roadie::Rails::Automatic
  helper :reservations

  def successful_checkin(checkin, email)
    @checkin = checkin
    @email = email
    mail(to: @email, subject: "##{checkin.reservation.confirmation_number} - Flight ##{checkin.flight.flight_number} - Successful Checkin")
  end
end
