class CreateAirports < ActiveRecord::Migration
  def change
    create_table :airports do |t|
      t.string :name
      t.string :city
      t.string :country
      t.string :iata
      t.string :icao
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.integer :airport_id
      t.integer :altitude
      t.decimal :timezone_offset
      t.column :dst, "char(1)"
      t.string :timezone

      t.timestamps null: false
    end
    add_index :airports, :iata
    add_index :airports, :icao
    add_index :airports, :airport_id, unique: true
  end
end
