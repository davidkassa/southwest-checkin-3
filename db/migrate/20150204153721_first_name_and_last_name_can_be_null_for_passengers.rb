class FirstNameAndLastNameCanBeNullForPassengers < ActiveRecord::Migration
  def change
    change_column_null :passengers, :first_name, true
    change_column_null :passengers, :last_name, true
  end
end
