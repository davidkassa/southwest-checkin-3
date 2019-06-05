class AddErrorToCheckin < ActiveRecord::Migration[4.2]
  def change
    add_column :checkins, :error, :text
  end
end
