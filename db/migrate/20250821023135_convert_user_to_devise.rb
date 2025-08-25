class ConvertUserToDevise < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :password_digest, :string

    ## Database authenticatable
    add_column :users, :encrypted_password, :string, null: false, default: ""

    ## Rememberable
    add_column :users, :remember_created_at, :datetime

    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    add_column :users, :from_google_oauth, :boolean, default: false
  end
end

