class Admin::UsersController < Admin::BaseController
  before_action :load_supervisors, only: %i(index)
  before_action :load_courses, only: %i(index)
  before_action :load_supervisor, only: %i(update_status)
  before_action :set_css_class, only: %i(index)

  # GET /admin/users
  def index
    @pagy, @supervisors = pagy(@user_supervisors)
  end

  # PATCH /admin/users/:id/update_status
  def update_status
    flash[:success] = t(".update_success") if update_status?

    redirect_to session.delete(:forwarding_url) || admin_users_path
  end

  # PATCH /admin/users/bulk_deactivate
  def bulk_deactivate
    handle_bulk_statuses
    redirect_to admin_users_path
  end

  private

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
      new_status = supervisor.activated? ? false : true
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

  def get_user_course
    @user_course =
      case action_name.to_sym
      when :update_user_course_status
        @user_supervisor.user_courses
                        .find_by(course_id: params[:course_id])
      when :delete_user_course
        @user_supervisor.user_courses.includes(USER_COURSE_INCLUDES)
                        .find_by(course_id: params[:course_id])
      end
    return if @user_course

    flash[:danger] = t(".course.not_found")
    redirect_to admin_user_path(@user_supervisor)
  end
end
