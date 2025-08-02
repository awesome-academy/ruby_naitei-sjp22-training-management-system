class AddIndexesToSubjectCategories < ActiveRecord::Migration[7.0]
  def change
    add_index :subject_categories, [:subject_id, :category_id], unique: true, if_not_exists: true
    add_index :subject_categories, :position, if_not_exists: true
  end
end
