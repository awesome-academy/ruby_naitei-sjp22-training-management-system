class SessionsController < ApplicationController
  before_action :validate_session_params, only: :create
  before_action :load_user, only: :create
  before_action :check_authentication, only: :create
  before_action :check_activation, only: :create

  REMEMBER_ME = "1".freeze

  # GET /login
  def new; end

  # POST /login
  def create
    handle_successful_login(@user)
  end

  # DELETE /logout
  def destroy
    log_out if logged_in?
    flash[:success] = t(".logout_success")
    redirect_to root_path, status: :see_other
  end

  private

  def validate_session_params
    if params.dig(:session, :email).present? &&
       params.dig(:session, :password).present?
      return
    end

    flash.now[:danger] = t(".missing_credentials")
    render :new, status: :unprocessable_entity
  end

  def load_user
    email = params.dig(:session, :email)&.downcase&.strip
    return handle_failed_login if email.blank?

    @user = User.find_by(email: email)
    return handle_failed_login unless @user
  end

  def check_authentication
    return if @user&.authenticate(session_password)

    handle_failed_login
  end

  def check_activation
    return if @user.activated?

    handle_unactivated_user
  end

  def session_password
    params.dig(:session, :password)
  end

  def handle_successful_login user
    forwarding_url = session[:forwarding_url]
    reset_session
    log_in(user)
    if params.dig(:session,
                  :remember_me) == REMEMBER_ME
      remember(user)
    else
      create_session(user)
    end
    flash[:success] = t(".login_success")
    redirect_to forwarding_url || user
  end

  def handle_failed_login
    flash.now[:danger] = t(".login_failed")
    render :new, status: :unprocessable_entity
  end

  def handle_unactivated_user
    flash[:warning] = t(".account_not_activated")
    redirect_to root_url
  end
end
