class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.datetime :departure_time, null: false
      t.datetime :arrival_time, null: false
      t.string :departure_city, null: false
      t.string :arrival_city, null: false
      t.json :payload, null: false
      t.references :departure_airport, index: true, null: false
      t.references :arrival_airport, index: true, null: false
      t.references :reservation, index: true, null: false

      t.timestamps null: false
    end
    add_foreign_key :flights, :airports, column: :departure_airport_id
    add_foreign_key :flights, :airports, column: :arrival_airport_id
    add_foreign_key :flights, :reservations
  end
end
