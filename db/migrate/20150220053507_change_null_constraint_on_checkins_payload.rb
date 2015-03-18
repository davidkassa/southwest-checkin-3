class ChangeNullConstraintOnCheckinsPayload < ActiveRecord::Migration
  def change
    change_column_null :checkins, :payload, true
  end
end
