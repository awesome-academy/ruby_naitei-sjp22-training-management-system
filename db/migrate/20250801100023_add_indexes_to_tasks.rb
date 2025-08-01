class AddIndexesToTasks < ActiveRecord::Migration[7.0]
  def change
    add_index :tasks, :name, if_not_exists: true
    add_index :tasks, :status, if_not_exists: true
    add_index :tasks, [:taskable_type, :taskable_id], if_not_exists: true
    add_index :tasks, :expected_time, if_not_exists: true
  end
end
