class AddUniqueIndexToCategoriesName < ActiveRecord::Migration[7.0]
  def change
    add_index :categories, :name, unique: true, if_not_exists: true
  end
end
