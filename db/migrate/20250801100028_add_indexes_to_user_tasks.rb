class AddIndexesToUserTasks < ActiveRecord::Migration[7.0]
  def change
    add_index :user_tasks, [:user_id, :task_id], unique: true, if_not_exists: true
    add_index :user_tasks, :user_subject_id, if_not_exists: true
    add_index :user_tasks, :status, if_not_exists: true
    add_index :user_tasks, :spent_time, if_not_exists: true
  end
end
