class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = find_or_create_user_from_auth

    if @user.persisted?
      handle_successful_login
    else
      handle_failed_login
    end
  end

  private

  def auth
    request.env["omniauth.auth"]
  end

  def find_or_create_user_from_auth
    User.find_or_create_by(email: auth.info.email) do |u|
      u.name = auth.info.name
      u.password = Devise.friendly_token[0, 20]
      u.role = :trainee
      u.confirmed_at = Time.zone.now
      u.from_google_oauth = true
    end
  end

  def handle_successful_login
    sign_in_and_redirect @user, event: :authentication
    flash[:success] =
      I18n.t("devise.omniauth_callbacks.success", kind: "Google")
  end

  def handle_failed_login
    redirect_to new_user_session_path,
                alert: I18n.t("devise.omniauth_callbacks.failure",
                              kind: "Google",
                              reason: "authentication error")
  end
end
