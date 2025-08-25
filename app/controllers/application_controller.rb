class ApplicationController < ActionController::Base
  include Pagy::Backend
  include UserLoadable

  protect_from_forgery with: :exception

  # --- SET LOCALE TRƯỚC DEVİSE ---
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
    # Đảm bảo locale luôn được set trước Devise redirect
    locale = params[:locale].presence || session[:locale] || I18n.default_locale
    I18n.locale = locale.to_sym
    session[:locale] = I18n.locale
  end

  def default_url_options
    # Trả về locale hiện tại để các URL helper có locale
    { locale: I18n.locale }
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
    session[:forwarding_url] = request.fullpath if storable_location?
  end

  def storable_location?
    request.get? && !request.xhr? && !devise_controller?
  end

  def after_sign_in_path_for _resource_or_scope
    session.delete(:forwarding_url) || root_path(locale: I18n.locale)
  end
end
