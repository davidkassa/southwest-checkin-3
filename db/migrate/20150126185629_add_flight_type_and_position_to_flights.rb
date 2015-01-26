class AddFlightTypeAndPositionToFlights < ActiveRecord::Migration
  def change
    add_column :flights, :flight_type, :integer, null: false, default: 0
    add_column :flights, :position, :integer, null: false
  end
end
