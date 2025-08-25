class ConvertUsersToDevise < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:users, :password_digest) && !column_exists?(:users, :encrypted_password)
      rename_column :users, :password_digest, :encrypted_password
    end

    if column_exists?(:users, :encrypted_password)
      change_column :users, :encrypted_password, :string, null: false, default: ""
    else
      add_column :users, :encrypted_password, :string, null: false, default: ""
    end

    ## Confirmable (chỉ dùng nếu bạn enable confirmable trong model User)
    unless column_exists?(:users, :confirmation_token)
      add_column :users, :confirmation_token, :string
      add_column :users, :confirmed_at, :datetime
      add_column :users, :confirmation_sent_at, :datetime
      add_column :users, :unconfirmed_email, :string
    end

    ## Indexes
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token)
  end
end
