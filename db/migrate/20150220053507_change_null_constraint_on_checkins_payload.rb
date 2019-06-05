class ChangeNullConstraintOnCheckinsPayload < ActiveRecord::Migration[4.2]
  def change
    change_column_null :checkins, :payload, true
  end
end
