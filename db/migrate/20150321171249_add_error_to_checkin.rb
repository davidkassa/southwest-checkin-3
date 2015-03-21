class AddErrorToCheckin < ActiveRecord::Migration
  def change
    add_column :checkins, :error, :text
  end
end
