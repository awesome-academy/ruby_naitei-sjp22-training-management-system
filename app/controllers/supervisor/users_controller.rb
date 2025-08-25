class Supervisor::UsersController < Supervisor::BaseController
  before_action :load_courses, only: %i(index)
  before_action :load_trainees, only: %i(index)
  before_action :load_trainee, only: %i(update_status show
  update_user_course_status delete_user_course update)
  before_action :set_css_class, only: %i(index show)
  before_action :require_manager
  before_action :load_user_course,
                only: %i(update_user_course_status delete_user_course)

  # GET supervisor/users
  def index
    @pagy, @trainees = pagy(@user_trainees)
  end

  # GET /supervisor/users/:id
  def show
    @trainee_courses = @user_trainee.courses
                                    .includes([:supervisors])
                                    .includes(user_courses: [:user_subjects])
                                    .by_user_course_status(params[:status])
                                    .search_by_name(params[:search])
                                    .by_course(params[:course]).recent
    @pagy, @trainee_courses = pagy(@trainee_courses)
  end

  # PATCH /supervisor/users/:id/update_status
  def update_status
    flash[:success] = t(".update_success") if handle_update_status?
    redirect_to session.delete(:forwarding_url) || supervisor_users_path
  end

  # PATCH /supervisor/users/bulk_deactivate
  def bulk_deactivate
    handle_bulk_statuses
    redirect_to supervisor_users_path
  end

  # PATCH /supervisor/users/:id/update_user_course_status
  def update_user_course_status
    flash[:success] = t(".update_success") if update_user_course_status?

    redirect_to supervisor_user_path(@user_trainee)
  end

  # PATCH /supervisor/users/:id/delete_user_course
  def delete_user_course
    flash[:success] = t(".delete_success") if delete_user_course?

    redirect_to supervisor_user_path(@user_trainee)
  end

  # PATCH /supervisor/users/:id/update
  def update
    if @user_trainee.update(user_params)
      flash[:success] = t(".update_success")
      redirect_to supervisor_user_path(@user_trainee)
    else
      flash[:danger] = t(".update_failed")
      render :show
    end
  end

  private

  def load_trainees
    @user_trainees = User.trainee.filter_by_name(params[:search])
                         .filter_by_status(params[:status])
                         .by_course(params[:course])
                         .recent
  end

  def load_courses
    @courses = Course.recent
  end

  def load_trainee
    @user_trainee = User.find_by(id: params[:id])
    return if @user_trainee

    flash[:danger] = t(".trainee.not_found")
    redirect_to supervisor_users_path
  end

  def handle_update_status?
    if params[:activated].present? &&
       @user_trainee.update(activated: params[:activated])
      return true
    end

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_bulk_statuses
    trainee_ids = params[:trainee_ids]

    return flash_no_selection if trainee_ids.blank?

    trainees = User.where(id: trainee_ids)
    updated_count = toggle_trainees_status(trainees)

    flash_bulk_status_result(updated_count)
  end

  def flash_bulk_status_result updated_count
    if updated_count.positive?
      flash[:success] = t(".bulk_statuses_success", count: updated_count)
    else
      flash[:danger] = t(".bulk_statuses_failed")
    end
  end

  def toggle_trainees_status trainees
    updated_count = 0
    trainees.each do |trainee|
      new_status = !trainee.activated?
      updated_count += 1 if trainee.update(activated: new_status)
    end
    updated_count
  end

  def flash_no_selection
    flash[:danger] = t(".trainee_no_selection")
    redirect_to supervisor_users_path
  end

  def set_css_class
    @page_class = Settings.page_classes.supervisor_users
  end

  def load_user_course
    @user_course =
      case action_name.to_sym
      when :update_user_course_status
        @user_trainee.user_courses
                     .find_by(course_id: params[:course_id])
      when :delete_user_course
        @user_trainee.user_courses.includes(UserCourse::USER_COURSE_INCLUDES)
                     .find_by(course_id: params[:course_id])
      end
    return if @user_course

    flash[:danger] = t(".course.not_found")
    redirect_to supervisor_user_path(@user_trainee)
  end

  def user_params
    params.require(:user).permit(User::PERMITTED_UPDATE_ATTRIBUTES)
  end

  def update_user_course_status?
    return true if @user_course.update(status: params[:status])

    flash[:danger] = t(".update_failed")
    false
  end

  def delete_user_course?
    return true if @user_course.destroy

    flash[:danger] = t(".delete_failed")
    false
  end
end
