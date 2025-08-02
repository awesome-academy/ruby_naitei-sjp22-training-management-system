class AddIndexesToDailyReports < ActiveRecord::Migration[7.0]
  def change
    add_index :daily_reports, [:user_id, :course_id], if_not_exists: true
    add_index :daily_reports, :is_done, if_not_exists: true
    add_index :daily_reports, :created_at, if_not_exists: true
  end
end
