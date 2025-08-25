class RemoveLegacyAuthFieldsFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :remember_digest, :string
    remove_column :users, :activation_digest, :string
    remove_column :users, :activated, :boolean, default: false
    remove_column :users, :activated_at, :datetime
    remove_column :users, :reset_digest, :string
    remove_column :users, :reset_sent_at, :datetime
  end
end

