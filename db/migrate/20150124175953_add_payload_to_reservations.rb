class AddPayloadToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :payload, :json, null: false
  end
end
