module AuthenticationHelper
  def sign_in user
    user.create_session
    session[:user_id] = user.id
    session[:session_token] = user.session_token
  end

  def sign_out
    session.delete(:user_id)
    session.delete(:session_token)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :controller
end
