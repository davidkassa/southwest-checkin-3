class AddFlightNumberToFlights < ActiveRecord::Migration[4.2]
  def change
    add_column :flights, :flight_number, :string
  end
end
