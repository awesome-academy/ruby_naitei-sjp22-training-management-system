# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  private
  def sign_up_params
    params.require(:user).permit(:name, :birthday, :gender, :role, :email,
                                 :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :birthday, :gender, :role, :email,
                                 :password, :password_confirmation,
                                 :current_password)
  end

  def after_inactive_sign_up_path_for _resource
    new_user_session_path
  end
end
