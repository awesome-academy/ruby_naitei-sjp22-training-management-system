class SessionsController < ApplicationController
  before_action :validate_session_params, only: :create
  before_action :load_user_by_session_email, only: :create
  # before_action :check_authentication, only: :create
  before_action :check_activation, only: :create
  before_action :logged_out_user, only: %i(new create)
  skip_before_action :logged_in_user, only: %i(new create create_from_google)
  skip_before_action :store_user_location, only: %i(create_from_google)

  REMEMBER_ME = "1".freeze

  # GET /login
  def new; end

  # POST /login
  def create
    user = User.find_by(email: params.dig(:session, :email))
    if valid_password?(user, params.dig(:session, :password))
      sign_in(user)
      handle_successful_login(user)
    else
      handle_failed_login
    end
  end

  # DELETE /logout
  def destroy
    flash[:success] = t(".logout_success")
    redirect_to login_url, status: :see_other
  end

  # POST /auth/google_oauth2/callback
  def create_from_google
    auth = request.env["omniauth.auth"]
    if auth.nil?
      return redirect_to(login_path,
                         alert: t("sessions.google_auth_failed"))
    end

    user = find_or_create_user_from_google(auth)
    handle_successful_login(user)
  end

  private

  def find_or_create_user_from_google auth
    user = User.find_or_initialize_by(email: auth.info.email)
    return user unless user.new_record?

    user.assign_attributes(
      name: auth.info.name,
      password: SecureRandom.hex(15),
      activated: true,
      activated_at: Time.zone.now,
      from_google_oauth: true,
      role: :trainee
    )

    unless user.save
      flash[:danger] = t(
        "sessions.google_create_failed",
        errors: user.errors.full_messages.join(", ")
      )
      redirect_to login_path and return
    end

    user
  end

  def validate_session_params
    if params.dig(:session, :email).present? &&
       params.dig(:session, :password).present?
      return
    end

    flash.now[:danger] = t(".missing_credentials")
    render :new, status: :unprocessable_entity
  end

  # def check_authentication
  #   return if @user&.authenticate(session_password)

  #   handle_failed_login
  # end

  def check_activation
    return if @user.activated?

    handle_unactivated_user
  end

  def session_password
    params.dig(:session, :password)
  end

  def handle_successful_login user
    forwarding_url = session[:forwarding_url]
    flash[:success] = t(".login_success")
    redirect_to forwarding_url || user
  end

  def handle_failed_login
    flash.now[:danger] = t(".login_failed")
    render :new, status: :unprocessable_entity
  end

  def handle_unactivated_user
    flash[:warning] = t(".account_not_activated")
    redirect_to login_url
  end
end
