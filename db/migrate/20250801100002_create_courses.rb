class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.date :start_date
      t.date :finish_date
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0
      t.timestamps
    end
  end
end
