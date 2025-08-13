class AddLinkToCourseToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :link_to_course, :string
  end
end
