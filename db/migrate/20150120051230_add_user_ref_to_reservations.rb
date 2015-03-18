class AddUserRefToReservations < ActiveRecord::Migration
  def change
    add_reference :reservations, :user, index: true
    add_foreign_key :reservations, :users
  end
end
