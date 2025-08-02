class CreateCourseSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :course_subjects do |t|
      t.references :course, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.integer :position
      t.date :start_date
      t.date :finish_date
      t.timestamps
    end
  end
end
