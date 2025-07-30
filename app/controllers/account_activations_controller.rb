class AccountActivationsController < ApplicationController
  before_action :load_user
  before_action :check_authentication, only: %i(edit)

  # GET /account_activations/:id/edit?email=email
  def edit
    activate_user
  end

  private

  def load_user
    @user = User.find_by(email: params[:email])
    return if @user

    flash[:danger] = t(".user_not_found")
    redirect_to root_url
  end

  def check_authentication
    return if !@user.activated && @user.authenticated?(:activation, params[:id])

    handle_invalid_activation
  end

  def activate_user
    @user.activate
    log_in(@user)
    flash[:success] = t(".account_activated")
    redirect_to @user
  end

  def handle_invalid_activation
    flash[:danger] = t(".invalid_activation_link")
    redirect_to root_url
  end
end
