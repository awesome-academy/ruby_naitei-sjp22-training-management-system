class CreateUserSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :user_subjects do |t|
      t.references :user_course, null: false, foreign_key: true
      t.references :course_subject, null: false, foreign_key: true
      t.integer :status, default: Settings.user_subject.status.not_started
      t.text :notes
      t.float :score
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
