module UserLoadable
  extend ActiveSupport::Concern

  private

  def load_user_by_id
    @user = User.find_by(id: params[:id])
    return if @user

    flash[:danger] = t("shared.user_not_found")
    redirect_to root_path
  end

  def load_user_by_email
    @user = User.find_by(email: params[:email])
    return if @user

    flash[:danger] = t("shared.user_not_found")
    redirect_to root_path
  end

  def load_user_by_password_reset_email
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    return if @user

    flash[:danger] = t("shared.user_not_found")
    redirect_to root_path
  end

  def load_user_by_session_email
    email = params.dig(:session, :email)&.downcase&.strip
    return handle_session_load_failure if email.blank?

    @user = User.find_by(email:)
    handle_session_load_failure unless @user
  end

  def handle_session_load_failure
    flash.now[:danger] = t("sessions.create.login_failed")
    render :new, status: :unprocessable_entity
  end

  def valid_user
    return if @user.confirmed? && @user.authenticated?(:reset, params[:id])

    flash[:danger] = t("password_resets.edit.user_inactive")
    redirect_to new_user_session_path
  end

  def check_expiration
    # Devise handles password reset expiration automatically
    return unless @user.reset_password_period_valid?

    flash[:danger] = t("password_resets.edit.expired_token")
    redirect_to new_password_path(resource_name)
  end
end
