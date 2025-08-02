class CreateUserTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :user_tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.references :user_subject, null: false, foreign_key: true
      t.integer :status, default: Settings.user_task.status.not_done
      t.integer :spent_time
      t.timestamps
    end
  end
end
