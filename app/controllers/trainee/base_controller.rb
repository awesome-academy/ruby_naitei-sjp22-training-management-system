class Trainee::BaseController < ApplicationController
  before_action :check_trainee_role
  layout "application"

  def check_trainee_role
    return if current_user&.trainee?

    flash[:danger] = t("messages.permission_denied")
    redirect_to root_path
  end
end
