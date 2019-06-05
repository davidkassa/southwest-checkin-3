class AddFirstNameAndLastNameToReservations < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :first_name, :string, null: false
    add_column :reservations, :last_name, :string, null: false
  end
end
