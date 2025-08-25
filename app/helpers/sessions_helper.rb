module SessionsHelper
  def log_in user
    session[:user_id] = user.id
  end

  def remember user
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def create_session user
    user.create_session
    session[:session_token] = user.session_token
  end

  def current_user? user
    user == current_user
  end

  def redirect_back_or default
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  private

  def find_user_by_session
    return unless user_id = session[:user_id]

    user = User.find_by id: user_id
    return unless user

    return unless user.authenticated?(:remember, session[:session_token])

    user
  end

  def find_user_by_remember_cookie
    return unless user_id = cookies.signed[:user_id]

    user = User.find_by id: user_id

    return unless user&.authenticated?(:remember, cookies[:remember_token])

    user
  end
end
