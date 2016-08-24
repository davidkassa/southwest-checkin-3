class RemoveTripNameAndArrivalCityNameFromReservations < ActiveRecord::Migration
  def up
    remove_columns :reservations, :trip_name, :arrival_city_name
  end

  def down
    add_column :reservations, :trip_name, :string
    add_column :reservations, :arrival_city_name, :string
  end
end
