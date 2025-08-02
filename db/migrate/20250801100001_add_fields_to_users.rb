class AddFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :nick_name, :string
    add_column :users, :role, :integer, default: 0
    add_column :users, :member_from, :date
    add_column :users, :member_to, :date
    add_column :users, :email_verified_at, :datetime
    add_column :users, :is_admin, :boolean, default: false
  end
end
