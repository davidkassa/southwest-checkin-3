class CreatePassengers < ActiveRecord::Migration
  def change
    create_table :passengers do |t|
      t.boolean :is_companion, default: false, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.references :reservation, index: true, null: false
      t.string :full_name, null: false

      t.timestamps null: false
    end
    add_foreign_key :passengers, :reservations
  end
end
