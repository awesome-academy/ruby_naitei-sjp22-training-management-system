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

    ## Recoverable
    add_column :users, :reset_password_token,   :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)

    ## Rememberable
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    ## Confirmable (chỉ dùng nếu bạn enable confirmable trong model User)
    unless column_exists?(:users, :confirmation_token)
      add_column :users, :confirmation_token, :string
      add_column :users, :confirmed_at, :datetime
      add_column :users, :confirmation_sent_at, :datetime
      add_column :users, :unconfirmed_email, :string
    end

    ## Trackable (tùy chọn, bỏ qua nếu không dùng)
    # unless column_exists?(:users, :sign_in_count)
    #   add_column :users, :sign_in_count, :integer, default: 0, null: false
    #   add_column :users, :current_sign_in_at, :datetime
    #   add_column :users, :last_sign_in_at, :datetime
    #   add_column :users, :current_sign_in_ip, :string
    #   add_column :users, :last_sign_in_ip, :string
    # end

    ## Indexes
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token)
  end
end
