class CreateFlightCheckins < ActiveRecord::Migration
  def change
    create_table :flight_checkins do |t|
      t.string :flight_number, null: false
      t.string :boarding_group, null: false
      t.integer :boarding_position, null: false
      t.belongs_to :flight, index: true, null: false
      t.belongs_to :checkin, index: true, null: false

      t.timestamps null: false
    end
    add_foreign_key :flight_checkins, :flights
    add_foreign_key :flight_checkins, :checkins
  end
end
