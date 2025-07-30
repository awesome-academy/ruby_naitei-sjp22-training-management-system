class UsersController < ApplicationController
  before_action :logged_in_user, only: %i(index edit update destroy)
  before_action :load_user, only: %i(show edit update destroy)
  before_action :correct_user, only: %i(edit update)
  before_action :admin_user, only: :destroy

  # GET /users
  def index
    @pagy, @users = pagy User.sort_by_name, items: Settings.ui.items_per_page
  end

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

  # DELETE /users/:id
  def destroy
    if @user.destroy
      flash[:success] = t(".user_deleted")
    else
      flash[:danger] = t(".delete_failed")
    end
    redirect_to users_path
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

  def load_user
    @user = User.find_by(id: params[:id])
    return if @user

    flash[:danger] = t(".user_not_found")
    redirect_to root_path
  end
end
