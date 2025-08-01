class AddIndexesToCourseSubjects < ActiveRecord::Migration[7.0]
  def change
    add_index :course_subjects, [:course_id, :subject_id], unique: true, if_not_exists: true
    add_index :course_subjects, :position, if_not_exists: true
    add_index :course_subjects, :start_date, if_not_exists: true
    add_index :course_subjects, :finish_date, if_not_exists: true
  end
end
