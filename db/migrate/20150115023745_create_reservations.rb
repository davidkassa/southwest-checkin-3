class CreateReservations < ActiveRecord::Migration
  def change
    create_table :reservations do |t|
      t.string :confirmation_number, null: false
      t.string :trip_name
      t.string :arrival_city_name, null: false

      t.timestamps null: false
    end
  end
end
