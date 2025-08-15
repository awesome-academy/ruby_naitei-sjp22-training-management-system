class Supervisor::CoursesController < Supervisor::BaseController
  include Supervisor::CoursesHelper

  EAGER_LOAD_SUBJECTS = [
    :subject,
    :tasks,
    {user_subjects: [:user, :comments]}
  ].freeze

  before_action :load_course, only: %i(show members subjects supervisors leave)
  before_action :authorize_supervisor_access!,
                only: %i(show members subjects supervisors leave)
  before_action :ensure_multiple_supervisors, only: [:leave]
  before_action :set_courses_page_class
  before_action :check_supervisor_role

  # GET /supervisor/courses
  def index
    @statuses = build_statuses

    courses_query = accessible_courses
                    .includes(:user)
                    .with_counts
                    .filter_by_params(params)
                    .ordered_by_start_date

    @pagy, @courses = pagy courses_query, limit: Settings.ui.items_per_page
  end

  # GET /supervisor/courses/:id
  def show
    redirect_to subjects_supervisor_course_path @course
  end

  # GET /supervisor/courses/:id/members
  def members
    @trainers = @course.supervisors.includes :user_courses
    @pagy, @trainees = pagy(
      @course.user_courses.trainees.includes(:user),
      limit: Settings.pagination.course_members_per_page
    )
    @trainee_count = @pagy.count
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count

    render template: Settings.templates.courses.members
  end

  # GET /supervisor/courses/:id/subjects
  def subjects
    @subjects = @course.course_subjects.includes(EAGER_LOAD_SUBJECTS)
    @subject_count = @subjects.count
    @trainee_count = @course.trainees_count
    @trainer_count = @course.supervisors.count

    render template: Settings.templates.courses.subjects
  end

  # GET /supervisor/courses/:id/supervisors
  def supervisors
    @trainers = @course.supervisors.includes :user_courses
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count
    @trainee_count = @course.trainees_count
  end

  # POST supervisor/courses
  def create
    @course = Course.new course_params.merge(user_id: current_user.id)

    if @course.save
      flash[:success] = t(".course_created_successfully")
      redirect_to supervisor_courses_path
    else
      flash[:danger] = t(".course_creation_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /supervisor/courses/:id/leave
  def leave
    if @course.supervisors.destroy(current_user)
      flash[:success] = t(".success")
      redirect_to supervisor_courses_path
    else
      flash[:danger] = t(".failed")
      redirect_back fallback_location: members_fallback_path
    end
  end

  # GET supervisor/courses/new
  def new
    @course = Course.new
    @course.course_subjects.build.build_subject
  end

  private

  def course_params
    params.require(:course).permit Course::COURSE_PARAMS
  end

  def accessible_courses
    if current_user&.admin?
      Course.all
    else
      Course.where(
        "courses.user_id = ? OR courses.id IN (
          SELECT course_id FROM course_supervisors WHERE user_id = ?
        )",
        current_user.id, current_user.id
      )
    end
  end

  def load_course
    @course = Course.find_by id: params[:id]
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def authorize_supervisor_access!
    return if current_user&.admin?

    return if allowed_for_supervisor?(@course)

    flash[:danger] = I18n.t("courses.errors.access_denied")
    redirect_to root_path
  end

  def allowed_for_supervisor? course
    return false unless course

    if read_only_action?
      course.user_id == current_user&.id ||
        course.supervisors.include?(current_user)
    else
      course.supervisors.include?(current_user)
    end
  end

  def read_only_action?
    %w(show members subjects).include?(action_name)
  end

  def set_courses_page_class
    self.page_class = if current_user&.admin?
                        Settings.page_classes.admin_courses
                      else
                        Settings.page_classes.courses
                      end
  end

  def ensure_multiple_supervisors
    return if @course.supervisors.count > 1

    flash[:danger] = t("courses.leave.must_have_another_supervisor")
    redirect_back fallback_location: members_fallback_path
  end

  def members_fallback_path
    members_supervisor_course_path(@course)
  end

  def subjects_fallback_path
    subjects_supervisor_course_path(@course)
  end
end
