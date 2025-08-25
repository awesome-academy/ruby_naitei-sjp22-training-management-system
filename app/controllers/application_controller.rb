class ApplicationController < ActionController::Base
  include Pagy::Backend
  include UserLoadable
  include Devise::Controllers::Helpers

  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :authenticate_user!
  before_action :store_user_location
  skip_before_action :authenticate_user!, if: :devise_controller?

  protected

  attr_accessor :page_class

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

  def logged_out_user
    return unless user_signed_in?

    flash[:info] = t("shared.already_logged_in")
    redirect_to root_url
  end

  def correct_user
    return if current_user.admin?

    return if current_user == @user

    flash[:danger] = t("shared.not_authorized")
    redirect_to root_path
  end

  def manager?
    return false unless current_user

    current_user.admin? || current_user.supervisor?
  end

  def require_manager
    return if manager?

    flash[:danger] = t("messages.permission_denied")
    redirect_to root_path
  end

  def store_user_location
    return unless request.get?
    return if request.xhr?
    return if devise_controller?

    session[:forwarding_url] = request.fullpath
  end

  def after_sign_in_path_for resource
    stored = stored_location_for(resource) || session.delete(:forwarding_url)
    return root_path if stored.blank?
    return root_path if stored == new_user_session_path

    stored
  end

  def after_sign_out_path_for _resource_or_scope
    root_path
  end
end
