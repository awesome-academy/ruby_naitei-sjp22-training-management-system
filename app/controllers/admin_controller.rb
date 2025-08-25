class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def show
    redirect_to admin_dashboard_path
  end

  private

  def authenticate_user!
    return if current_user

    redirect_to new_user_session_path
  end

  def authorize_admin!
    return if manager?

    redirect_to root_path
  end
end
