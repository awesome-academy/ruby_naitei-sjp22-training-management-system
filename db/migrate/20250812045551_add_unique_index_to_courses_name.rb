class AddUniqueIndexToCoursesName < ActiveRecord::Migration[7.0]
  def change
    add_index :courses, :name, unique: true
  end
end
