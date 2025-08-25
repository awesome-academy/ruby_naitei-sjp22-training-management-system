class Admin::AdminUsersController < Admin::BaseController
  before_action :load_admin, only: %i(show destroy activate deactivate)
  before_action :load_supervisor, only: :promote
  authorize_resource class: "User"

  # GET /admin/admin_users
  def index
    admins_scope = User.admin
                       .sort_by_name
                       .filter_by_name(params[:search])
                       .filter_by_status(params[:status])

    @pagy, @admins = pagy admins_scope, limit: Settings.ui.items_per_page
  end

  # GET /admin/admin/users/:id
  def show
    courses_scope = @admin.supervised_courses

    courses_scope = courses_scope.with_counts.recent
    @pagy, @courses = pagy courses_scope, limit: Settings.ui.items_per_page
  end

  # GET /admin/admin/users/new
  def new
    @supervisor = User.new
  end

  # POST /admin/admin/users
  def create
    @supervisor = User.new supervisor_params.merge(role: :admin)

    if @supervisor.save
      flash[:success] = t(".admin_created_successfully")
      redirect_to admin_admin_users_path, status: :see_other
    else
      flash.now[:danger] = t(".creation_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH /admin/admin/users/:id/activate
  def activate
    if @admin.activate
      flash[:success] = t(".admin_activated")
    else
      flash[:danger] = t(".activation_failed")
    end
    redirect_to admin_admin_users_path, status: :see_other
  end

  # PATCH /admin/admin/users/:id/deactivate
  def deactivate
    if @admin.update(confirmed_at: nil)
      flash[:success] = t(".admin_deactivated")
    else
      flash[:danger] = t(".deactivation_failed")
    end
    redirect_to admin_admin_users_path, status: :see_other
  end

  # DELETE /admin/admin/users/:id
  def destroy
    if @admin.destroy
      flash[:success] = t(".admin_deleted")
    else
      flash[:danger] = t(".deletion_failed")
    end
    redirect_to admin_admin_users_path, status: :see_other
  end

  # PATCH /admin/admin/users/promote
  def promote
    if @supervisor.update(role: :admin)
      flash[:success] = t(".promote_success")
    else
      flash[:danger] = t(".promote_failed")
    end
    redirect_to admin_admin_users_path
  end

  private

  def load_supervisor
    @supervisor = User.find_by(id: params[:supervisor_id], role: :supervisor)
    return if @supervisor

    redirect_to admin_admin_users_path, alert: t("users.show.user_not_found")
  end

  def load_admin
    @admin = User.admin.find_by(id: params[:id])
    return if @admin

    redirect_to admin_admin_users_path, alert: t("users.show.user_not_found")
  end

  def supervisor_params
    params.require(:user).permit User::PERMITTED_ATTRIBUTES
  end
end
