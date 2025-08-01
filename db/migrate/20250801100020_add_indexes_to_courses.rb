class AddIndexesToCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :courses, :name, if_not_exists: true
    add_index :courses, :start_date, if_not_exists: true
    add_index :courses, :finish_date, if_not_exists: true
    add_index :courses, :status, if_not_exists: true
    add_index :courses, :user_id, if_not_exists: true
  end
end
