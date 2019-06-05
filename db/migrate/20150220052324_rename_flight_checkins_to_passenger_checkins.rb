class RenameFlightCheckinsToPassengerCheckins < ActiveRecord::Migration[4.2]
  def change
    rename_table :flight_checkins, :passenger_checkins
  end
end
