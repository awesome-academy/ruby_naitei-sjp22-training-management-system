class AddUniqueIndexToCourseCategories < ActiveRecord::Migration[7.0]
  def change
    add_index :course_categories, [:course_id, :category_id], unique: true, if_not_exists: true
  end
end
