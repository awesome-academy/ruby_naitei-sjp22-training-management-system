class AddIndexesToCategories < ActiveRecord::Migration[7.0]
  def change
    add_index :categories, :name, if_not_exists: true
  end
end
