class Admin::UsersController < Admin::BaseController
  before_action :require_admin, only: %i(activate deactivate)

  def index
    admins_scope = User.admin.sort_by_name

    if params[:search].present?
      admins_scope = admins_scope.filter_by_name params[:search]
    end
    if params[:status].present?
      admins_scope = admins_scope.filter_by_status params[:status]
    end

    @pagy, @admins = pagy admins_scope, items: Settings.ui.items_per_page
  end

  # GET /admin/supervisors/new
  def new
    @supervisor = User.new
  end

  # POST /admin/users
  def create
    @supervisor = User.new supervisor_params
    @supervisor.role = :admin

    if @supervisor.save
      flash[:success] = t(".admin_created_successfully")
      redirect_to admin_users_path, status: :see_other
    else
      flash.now[:danger] = t(".creation_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def activate
    if @admin.activate
      flash[:success] = t(".admin_activated")
    else
      flash[:danger] = t(".activation_failed")
    end
    redirect_to admin_users_path, status: :see_other
  end

  def deactivate
    if @admin.update(activated: false)
      flash[:success] = t(".admin_deactivated")
    else
      flash[:danger] = t(".deactivation_failed")
    end
    redirect_to admin_users_path, status: :see_other
  end

  def destroy
    if @admin.destroy
      flash[:success] = t(".admin_deleted")
    else
      flash[:danger] = t(".deletion_failed")
    end
    redirect_to admin_users_path, status: :see_other
  end

  private

  def require_admin
    @admin = User.admin.find params[:id]
  end

  def supervisor_params
    params.require(:user).permit User::PERMITTED_ATTRIBUTES
  end
end
