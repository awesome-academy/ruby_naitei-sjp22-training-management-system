class UsersController < ApplicationController
  before_action :load_user_by_id, only: %i(show edit update)
  before_action :correct_user, only: %i(edit update)
  skip_before_action :authenticate_user!, only: %i(show)

  # GET /users/:id
  def show; end

  # GET /users/:id/edit
  def edit; end

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

  def user_params
    params.require(:user).permit User::PERMITTED_UPDATE_ATTRIBUTES
  end
end
