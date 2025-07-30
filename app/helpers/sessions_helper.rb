module SessionsHelper
  def log_in user
    session[:user_id] = user.id
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= authenticate_session_user(user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by id: user_id
      if user&.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def logged_in?
    current_user.present?
  end

  def log_out
    forget(current_user) if logged_in?
    reset_session
    @current_user = nil
  end

  def remember user
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget user
    user.forget
    cookies.delete :user_id
    cookies.delete :remember_token
  end

  def create_session user
    user.create_session
    session[:session_token] = user.session_token
  end

  def current_user? user
    user == current_user
  end

  def current_user_admin?
    current_user&.admin?
  end

  def redirect_back_or default
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  private

  def authenticate_session_user user_id
    user = User.find_by id: user_id
    return unless user

    user if user.authenticated?(:remember, session[:session_token])
  end
end
