class AddUserRefToReservations < ActiveRecord::Migration[4.2]
  def change
    add_reference :reservations, :user, index: true
    add_foreign_key :reservations, :users
  end
end
