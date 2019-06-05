class FirstNameAndLastNameCanBeNullForPassengers < ActiveRecord::Migration[4.2]
  def change
    change_column_null :passengers, :first_name, true
    change_column_null :passengers, :last_name, true
  end
end
