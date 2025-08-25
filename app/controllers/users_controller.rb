class UsersController < Devise::RegistrationsController
  before_action :load_user_by_id, only: %i(show update)
  before_action :correct_user, only: %i(update)

  # GET /users/:id
  def show; end

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
    params.require(:user).permit User::PERMITTED_ATTRIBUTES
  end
end
