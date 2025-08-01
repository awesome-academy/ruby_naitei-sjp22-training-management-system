class AddIndexesToUserSubjects < ActiveRecord::Migration[7.0]
  def change
    add_index :user_subjects, [:user_course_id, :course_subject_id], unique: true, if_not_exists: true
    add_index :user_subjects, :started_at, if_not_exists: true
    add_index :user_subjects, :completed_at, if_not_exists: true
    add_index :user_subjects, :status, if_not_exists: true
    add_index :user_subjects, :score, if_not_exists: true
  end
end
