class ReservationMailerPreview < ActionMailer::Preview
  def new_reservation
    reservation = Reservation.first
    ReservationMailer.new_reservation(reservation)
  end
end
