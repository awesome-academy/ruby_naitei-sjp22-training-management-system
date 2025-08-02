class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.references :taskable, polymorphic: true, null: false
      t.string :name, null: false
      t.text :description
      t.integer :expected_time
      t.integer :status, default: Settings.task.status.new
      t.timestamps
    end
  end
end
