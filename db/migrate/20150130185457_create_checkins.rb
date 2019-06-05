class CreateCheckins < ActiveRecord::Migration[4.2]
  def change
    create_table :checkins do |t|
      t.belongs_to :reservation, index: true, null: false
      t.json :payload, null: false

      t.timestamps null: false
    end
    add_foreign_key :checkins, :reservations
  end
end
