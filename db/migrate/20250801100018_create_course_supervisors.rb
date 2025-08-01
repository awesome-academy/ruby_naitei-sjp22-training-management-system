class CreateCourseSupervisors < ActiveRecord::Migration[7.0]
  def change
    create_table :course_supervisors do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
