class AddIndexesToSubjects < ActiveRecord::Migration[7.0]
  def change
    add_index :subjects, :name, if_not_exists: true
    add_index :subjects, :max_score, if_not_exists: true
    add_index :subjects, :estimated_time_days, if_not_exists: true
  end
end
