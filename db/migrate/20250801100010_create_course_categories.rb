class CreateCourseCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :course_categories do |t|
      t.references :course, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end
  end
end
