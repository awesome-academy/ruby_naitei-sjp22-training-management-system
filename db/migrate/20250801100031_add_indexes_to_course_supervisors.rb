class AddIndexesToCourseSupervisors < ActiveRecord::Migration[7.0]
  def change
    add_index :course_supervisors, [:course_id, :user_id], unique: true, if_not_exists: true
    add_index :course_supervisors, :user_id, if_not_exists: true
    add_index :course_supervisors, :course_id, if_not_exists: true
  end
end
