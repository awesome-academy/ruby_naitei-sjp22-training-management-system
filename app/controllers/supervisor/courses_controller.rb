class Supervisor::CoursesController < Supervisor::BaseController
  include Supervisor::CoursesHelper

  EAGER_LOAD_SUBJECTS = [
    {subject: {image_attachment: :blob}},
    :tasks,
    {user_subjects: [:user, :comments]}
  ].freeze

  SUPERVISORS_INCLUDES = [:user_courses].freeze
  COURSE_PRELOAD = {course_subjects: [:subject, :tasks, :user_subjects]}.freeze

  # Member type constants
  MEMBER_TYPE_TRAINER = "trainer".freeze
  MEMBER_TYPE_TRAINEE = "trainee".freeze

  # Template constants
  TEMPLATE_COURSES_EDIT = "courses/edit".freeze

  # Error message constants
  ERROR_ADD_SUBJECT_FAILED = "add_subject failed: %<class>s: %<message>s".freeze

  before_action :load_course,
                only: %i(show members subjects supervisors leave search_members
                        edit update add_subject)
  before_action :load_subject_to_add, only: [:add_subject]
  before_action :validate_subject_for_add, only: [:add_subject]
  before_action :authorize_supervisor_access!,
                only: %i(show members subjects supervisors leave search_members)
  before_action :ensure_multiple_supervisors, only: [:leave]
  before_action :set_courses_page_class

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
    @trainers = @course.supervisors.includes SUPERVISORS_INCLUDES
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
                       .ordered_by_position
    @subject_count = @subjects.count
    @trainee_count = @course.trainees_count
    @trainer_count = @course.supervisors.count

    render template: Settings.templates.courses.subjects
  end

  # GET /supervisor/courses/:id/search_members
  def search_members
    users = find_available_users
    render json: users.select(:id, :name, :email)
  end

  # GET /supervisor/courses/:id/supervisors
  def supervisors
    @trainers = @course.supervisors.includes SUPERVISORS_INCLUDES
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

  # GET /supervisor/courses/:id/edit
  def edit
    @subjects = @course.course_subjects.includes(EAGER_LOAD_SUBJECTS)
                       .ordered_by_position
    render template: TEMPLATE_COURSES_EDIT
  end

  # PATCH /supervisor/courses/:id
  def update
    if update_course_with_reorder(course_params)
      flash[:success] = t(".course_updated_successfully")
      redirect_to subjects_supervisor_course_path(@course)
    else
      reload_subjects_for_edit
      flash[:danger] = t(".course_update_failed")
      render template: TEMPLATE_COURSES_EDIT, status: :unprocessable_entity
    end
  end

  def update_course_with_reorder permitted_params
    CourseSubject.transaction do
      @course.assign_attributes(permitted_params)
      raise ActiveRecord::Rollback unless @course.save
    end
    @course.errors.empty?
  end

  # POST /supervisor/courses/:id/add_subject
  def add_subject
    course_subject = @course.course_subjects.build(
      subject: @subject,
      position: next_position
    )

    ActiveRecord::Base.transaction do
      course_subject.save!
      copy_subject_tasks_to_course_subject(@subject, course_subject)
      create_user_subjects_for_existing_trainees(course_subject)
    end

    render json: {
      success: true,
      message: t(".subject_added_successfully", subject_name: @subject.name)
    }
  rescue StandardError => e
    Rails.logger.error(format(ERROR_ADD_SUBJECT_FAILED,
                              class: e.class, message: e.message))
    render json: {success: false, message: t(".failed_to_add_subject")},
           status: :unprocessable_entity
  end

  private

  def find_available_users
    member_type = determine_member_type
    users = User.where(role: User.roles[member_type])
    existing_ids = existing_user_ids?(member_type)
    users = users.where.not(id: existing_ids)
    users = apply_search_filter(users)
    users.sort_by_name.limit(20)
  end

  def determine_member_type
    params[:type] == MEMBER_TYPE_TRAINER ? :supervisor : :trainee
  end

  def existing_user_ids? member_type
    if member_type == :trainee
      @course.users.where(role: :trainee).pluck(:id)
    else
      @course.supervisors.pluck(:id)
    end
  end

  def apply_search_filter users
    query = params[:q].to_s
    return users if query.blank?

    users.filter_by_name(query)
  end

  def copy_subject_tasks_to_course_subject subject, course_subject
    subject.tasks.each do |subject_task|
      course_subject.tasks.create!(
        name: subject_task.name
      )
    end
  end

  def reload_subjects_for_edit
    @course.reload
    @subjects = @course.course_subjects.includes(EAGER_LOAD_SUBJECTS)
                       .ordered_by_position
  end

  def create_user_subjects_for_existing_trainees course_subject
    @course.user_courses.includes(:user).each do |user_course|
      next unless user_course.user.trainee?

      user_subject = course_subject.user_subjects.create!(
        user: user_course.user,
        user_course: user_course,
        status: Settings.user_subject.status.not_started
      )

      create_user_tasks_for_user_subject(user_subject, course_subject)
    end
  end

  def create_user_tasks_for_user_subject user_subject, course_subject
    course_subject.tasks.each do |task|
      user_subject.user_tasks.create!(
        user: user_subject.user,
        task: task,
        status: Settings.user_task.status.not_done
      )
    end
  end

  def next_position
    @course.course_subjects.maximum(:position).to_i + 1
  end

  def render_subject_not_found
    render json: {success: false, message: t(".subject_not_found")},
           status: :not_found
  end

  def render_subject_already_added
    render json: {success: false, message: t(".subject_already_added")},
           status: :unprocessable_entity
  end

  def load_subject_to_add
    @subject = Subject.find_by(id: params[:subject_id])
    return if @subject

    render_subject_not_found
  end

  def validate_subject_for_add
    return unless @subject
    return unless @course.subjects.include?(@subject)

    render_subject_already_added
  end

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
    @course = Course.includes(COURSE_PRELOAD)
                    .find_by(id: params[:id])
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
