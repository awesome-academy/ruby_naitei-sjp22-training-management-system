class AddIndexesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :nick_name, if_not_exists: true
    add_index :users, :role, if_not_exists: true
    add_index :users, :is_admin, if_not_exists: true
    add_index :users, :member_from, if_not_exists: true
    add_index :users, :member_to, if_not_exists: true
    add_index :users, :email_verified_at, if_not_exists: true
    add_index :users, [:role, :is_admin], if_not_exists: true
    add_index :users, [:member_from, :member_to], if_not_exists: true
  end
end
