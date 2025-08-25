class Admin::BaseController < ApplicationController
  before_action :check_admin_role
  before_action :set_count_create_task

  def check_admin_role
    return if current_user&.admin?

    flash[:danger] = t("messages.permission_denied")
    redirect_to root_path
  end

  def set_count_create_task
    session[:count_create_task] ||= 0
  end
end
