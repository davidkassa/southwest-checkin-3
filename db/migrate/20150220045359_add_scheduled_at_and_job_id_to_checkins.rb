class AddScheduledAtAndJobIdToCheckins < ActiveRecord::Migration
  class Checkin < ActiveRecord::Base
  end

  def change
    add_column :checkins, :scheduled_at, :datetime
    add_column :checkins, :job_id, :string
    add_column :checkins, :completed_at, :datetime

    Checkin.find_each do |checkin|
      checkin.update(scheduled_at: checkin.created_at)
    end

    change_column_null :checkins, :scheduled_at, false
  end
end
