class AddPassengerIdToFlightCheckins < ActiveRecord::Migration[4.2]
  def change
    add_reference :flight_checkins, :passenger, index: true, null: false
    add_foreign_key :flight_checkins, :passengers
  end
end
