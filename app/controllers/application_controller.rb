class ApplicationController < ActionController::Base
  include Pagy::Backend
  protect_from_forgery with: :exception

  include SessionsHelper

  before_action :set_locale

  private

  def set_locale
    locale = params[:locale]
    allowed_locales = I18n.available_locales.map(&:to_s)
    I18n.locale = if locale && allowed_locales.include?(locale)
                    locale
                  else
                    session[:locale] || I18n.default_locale
                  end
    session[:locale] = I18n.locale
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = t("shared.login_required")
    store_location
    redirect_to login_url
  end

  def admin_user
    return if current_user&.admin?

    flash[:danger] = t("shared.admin_required")
    redirect_to root_path
  end

  def correct_user
    return if current_user?(@user)

    flash[:danger] = t("shared.not_authorized")
    redirect_to root_path
  end
end
