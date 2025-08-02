class AddIndexesToUserCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :user_courses, [:user_id, :course_id], unique: true, if_not_exists: true
    add_index :user_courses, :joined_at, if_not_exists: true
    add_index :user_courses, :finished_at, if_not_exists: true
  end
end
