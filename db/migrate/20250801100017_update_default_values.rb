class UpdateDefaultValues < ActiveRecord::Migration[7.0]
  def up
    # Update subjects table with default max_score from settings
    change_column_default :subjects, :max_score, 100
    
    # Update users table with default role (trainee = 0)
    change_column_default :users, :role, 0
    
    # Update users table with default is_admin
    change_column_default :users, :is_admin, false
  end

  def down
    # Revert changes if needed
    change_column_default :subjects, :max_score, 100
    change_column_default :users, :role, 0
    change_column_default :users, :is_admin, false
  end
end
