class CleanUpUsersForDevise < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :remember_digest, :string if column_exists?(:users, :remember_digest)
    remove_column :users, :activation_digest, :string if column_exists?(:users, :activation_digest)
    remove_column :users, :activated, :boolean if column_exists?(:users, :activated)
    remove_column :users, :activated_at, :datetime if column_exists?(:users, :activated_at)
    remove_column :users, :reset_digest, :string if column_exists?(:users, :reset_digest)
    remove_column :users, :reset_sent_at, :datetime if column_exists?(:users, :reset_sent_at)
  end
end
