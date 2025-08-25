class ApplicationController < ActionController::Base
  include Pagy::Backend
  include UserLoadable
  include CanCan::ControllerAdditions
  rescue_from CanCan::AccessDenied, with: :user_not_authorized

  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :authenticate_user!
  before_action :store_user_location!, if: :storable_location?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  attr_accessor :page_class

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: User::PERMITTED_ATTRIBUTES)
  end

  private

  # --- I18n ---
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

  # --- Authorization helpers ---
  def correct_user
    return if current_user.admin?
    return if current_user == @user

    flash[:danger] = t("shared.not_authorized")
    redirect_to root_path
  end

  def manager?
    current_user&.admin? || current_user&.supervisor?
  end

  def require_manager
    return if manager?

    flash[:danger] = t("messages.permission_denied")
    redirect_to root_path
  end

  # --- Devise friendly forwarding ---
  def store_user_location!
    session[:forwarding_url] = request.fullpath
  end

  def storable_location?
    request.get? && !request.xhr? && !devise_controller?
  end

  def after_sign_in_path_for _resource_or_scope
    session.delete(:forwarding_url) || root_path
  end

  def user_not_authorized _exception
    flash[:danger] = t("shared.not_authorized")
    redirect_to(request.referer || root_path)
  end
end
