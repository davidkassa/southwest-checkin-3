class AddFlightTypeAndPositionToFlights < ActiveRecord::Migration[4.2]
  def change
    add_column :flights, :flight_type, :integer, null: false, default: 0
    add_column :flights, :position, :integer, null: false
  end
end
