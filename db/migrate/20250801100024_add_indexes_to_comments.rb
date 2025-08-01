class AddIndexesToComments < ActiveRecord::Migration[7.0]
  def change
    add_index :comments, [:commentable_type, :commentable_id], if_not_exists: true
    add_index :comments, :user_id, if_not_exists: true
    add_index :comments, :created_at, if_not_exists: true
  end
end
