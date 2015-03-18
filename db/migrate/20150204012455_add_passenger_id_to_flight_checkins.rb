class AddPassengerIdToFlightCheckins < ActiveRecord::Migration
  def change
    add_reference :flight_checkins, :passenger, index: true, null: false
    add_foreign_key :flight_checkins, :passengers
  end
end
