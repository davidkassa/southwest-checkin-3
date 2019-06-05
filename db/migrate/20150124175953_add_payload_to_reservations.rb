class AddPayloadToReservations < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :payload, :json, null: false
  end
end
