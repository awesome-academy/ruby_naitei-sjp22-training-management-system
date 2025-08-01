class CreateSubjectCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :subject_categories do |t|
      t.references :subject, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :position
      t.timestamps
    end
  end
end
