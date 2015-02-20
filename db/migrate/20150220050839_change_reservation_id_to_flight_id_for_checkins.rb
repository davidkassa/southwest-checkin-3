class ChangeReservationIdToFlightIdForCheckins < ActiveRecord::Migration
  class Reservation < ActiveRecord::Base
    has_many :flights, inverse_of: :reservation, autosave: true
    has_one :checkin
  end

  class Flight < ActiveRecord::Base
    belongs_to :reservation, inverse_of: :flights
  end

  class Checkin < ActiveRecord::Base
    belongs_to :flight
    belongs_to :reservation
  end

  def up
    add_reference :checkins, :flight, index: true

    Checkin.find_each do |checkin|
      checkin.update(flight_id: checkin.reservation.flights.first.id)
    end

    remove_reference :checkins, :reservation, index: true
    change_column_null :checkins, :flight_id, false
  end

  def down
    add_reference :checkins, :reservation, index: true

    Checkin.find_each do |checkin|
      checkin.update(reservation_id: checkin.flight.reservation.id)
    end

    remove_reference :checkins, :flight, index: true
    change_column_null :checkins, :reservation_id, false
  end
end
