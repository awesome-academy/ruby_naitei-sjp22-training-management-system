class Admin::UsersController < Admin::BaseController
  before_action :load_supervisors, only: %i(index)
  before_action :load_courses, only: %i(index)
  before_action :load_trainees, only: %i(new_supervisor add_role_supervisor)
  before_action :load_supervisor,
                only: %i(update_status show update delete_user_course)
  before_action :set_css_class, only: %i(index show)
  before_action :load_user_course, only: %i(delete_user_course)

  # GET /admin/users
  def index
    @pagy, @supervisors = pagy(@user_supervisors)
  end

  # GET /admin/users/new_supervisor
  def new_supervisor; end

  # PATCH /admin/users/:id/update_status
  def update_status
    flash[:success] = t(".update_success") if update_status?

    redirect_to session.delete(:forwarding_url) || admin_users_path
  end

  # GET /admin/users/:id
  def show
    @supervisor_courses = @user_supervisor.supervised_courses
                                          .includes(:users)
                                          .by_user_course_status(
                                            params[:status]
                                          )
                                          .search_by_name(params[:search])
                                          .by_course(params[:course_id]).recent
    @pagy, @supervisor_courses = pagy(@supervisor_courses)
  end

  # PATCH /admin/users/:id
  def update
    if @user_supervisor.update(user_params)
      flash[:success] = t(".update_success")
      redirect_to admin_user_path(@user_supervisor)
    else
      flash[:danger] = t(".update_failed")
      render :show
    end
  end

  # DELETE /admin/users/:id
  def delete_user_course
    flash[:success] = t(".delete_success") if handle_delete_user_course

    redirect_to admin_user_path(@user_supervisor)
  end

  # PATCH /admin/users/bulk_deactivate
  def bulk_deactivate
    handle_bulk_statuses
    redirect_to admin_users_path
  end

  # PATCH /admin/users/add_role_supervisor
  def add_role_supervisor
    flash[:success] = t(".add_success") if handle_add_role_supervisor?

    redirect_to new_supervisor_admin_users_path
  end

  private

  def load_trainees
    @user_trainees = User.trainee.filter_by_name(params[:search]).recent
  end

  def load_user_course
    @user_course = @user_supervisor.course_supervisors
                                   .find_by(course_id: params[:course_id])
    return if @user_course

    flash[:danger] = t(".course.not_found")
    redirect_to admin_user_path(@user_supervisor)
  end

  def handle_delete_user_course
    return true if @user_course.destroy

    flash[:danger] = t(".delete_failed")
    false
  end

  def user_params
    params.require(:user).permit(User::PERMITTED_UPDATE_ATTRIBUTES)
  end

  def load_supervisors
    @user_supervisors = User.supervisor.filter_by_name(params[:search])
                            .filter_by_status(params[:status])
                            .by_course(params[:course])
                            .recent
  end

  def load_courses
    @courses = Course.recent
  end

  def load_supervisor
    @user_supervisor = User.find_by(id: params[:id])
    return if @user_supervisor

    flash[:danger] = t(".supervisor.not_found")
    redirect_to admin_users_path
  end

  def update_status?
    if params[:activated].present? &&
       @user_supervisor.update(activated: params[:activated])
      return true
    end

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_bulk_statuses
    supervisor_ids = params[:supervisor_ids]

    return flash_no_selection if supervisor_ids.blank?

    supervisors = User.where(id: supervisor_ids)
    updated_count = toggle_supervisors_status(supervisors)

    flash_bulk_status_result(updated_count)
  end

  def flash_bulk_status_result updated_count
    if updated_count.positive?
      flash[:success] = t(".bulk_statuses_success", count: updated_count)
    else
      flash[:danger] = t(".bulk_statuses_failed")
    end
  end

  def toggle_supervisors_status supervisors
    updated_count = 0
    supervisors.each do |supervisor|
      new_status = !supervisor.activated?
      updated_count += 1 if supervisor.update(activated: new_status)
    end
    updated_count
  end

  def flash_no_selection
    flash[:danger] = t(".supervisor_no_selection")
    redirect_to admin_users_path
  end

  def set_css_class
    @page_class = Settings.page_classes.admin_users
  end

  def handle_add_role_supervisor?
    return false if params[:supervisor_ids].blank?

    begin
      @user_trainees.where(id: params[:supervisor_ids])
                    .update_all(role: :supervisor)
    rescue StandardError
      flash[:danger] = t(".add_failed")
      false
    end
    true
  end
end
