class RemoveIndexFromSubjectCategories < ActiveRecord::Migration[7.0]
  def change
    remove_index :subject_categories, [:category_id, :position], name: "index_subject_categories_on_category_and_position"
  end
end
