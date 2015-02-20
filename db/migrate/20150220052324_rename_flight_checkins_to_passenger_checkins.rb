class RenameFlightCheckinsToPassengerCheckins < ActiveRecord::Migration
  def change
    rename_table :flight_checkins, :passenger_checkins
  end
end
