class CreateSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :subjects do |t|
      t.string :name, null: false
      t.integer :max_score, default: Settings.subject.default_max_score
      t.integer :estimated_time_days
      t.timestamps
    end
  end
end
