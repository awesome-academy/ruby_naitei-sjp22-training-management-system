class PasswordResetsController < ApplicationController
  before_action :load_user_by_password_reset_email, only: :create
  before_action :load_user_by_email, :valid_user, :check_expiration,
                only: %i(edit update)
  before_action :check_password_presence, only: :update
  skip_before_action :authenticate_user!, only: %i(new create)

  # GET /password_resets/new
  def new; end

  # GET /password_resets/:id/edit?email=:email
  def edit; end

  # POST /password_resets
  def create
    @user.create_reset_digest
    @user.send_password_reset_email
    flash[:info] = t(".email_sent")
    redirect_to login_url
  end

  # PATCH /password_resets/:id
  def update
    if @user.update(user_params)
      handle_successful_password_reset
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def check_password_presence
    return unless user_params[:password].empty?

    @user.errors.add(:password, t(".password_empty"))
    render :edit, status: :unprocessable_entity
  end

  def handle_successful_password_reset
    log_in(@user)
    @user.send_password_changed_email
    flash[:success] = t(".password_reset_success")
    redirect_to @user
  end

  def user_params
    params.require(:user)
          .permit(User::PASSWORD_RESET_ATTRIBUTES)
          .merge(reset_digest: nil)
  end
end
