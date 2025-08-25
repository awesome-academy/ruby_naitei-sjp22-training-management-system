class UsersController < ApplicationController
  before_action :load_user_by_id, only: %i(show edit update)
  before_action :correct_user, only: %i(edit update)
  before_action :logged_out_user, only: %i(new create)
  skip_before_action :authenticate_user!, only: %i(new create)

  # GET /users/:id
  def show; end

  # GET /users/:id/edit
  def edit; end

  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    if @user.save
      handle_successful_signup
    else
      handle_failed_signup
    end
  end

  # PATCH /users/:id
  def update
    if @user.update user_params
      flash[:success] = t(".profile_updated")
      redirect_to @user, status: :see_other
    else
      flash.now[:danger] = t(".update_failed")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def handle_successful_signup
    @user.send_activation_email
    flash[:info] = t(".activation_email_sent")
    redirect_to root_url, status: :see_other
  end

  def handle_failed_signup
    render :new, status: :unprocessable_entity
  end

  def user_params
    params.require(:user).permit User::PERMITTED_ATTRIBUTES
  end
end
