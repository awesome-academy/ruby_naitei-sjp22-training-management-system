class Trainee::CoursesController < Trainee::BaseController
  COURSE_SUBJECTS_PRELOAD = [
    :subject,
    :tasks,
    {user_subjects: [:user, :comments]}
  ].freeze

  USER_SJ_PRELOAD = [
    :course_subject,
    :user_tasks,
    {comments: :user}
  ].freeze
  before_action :load_course, only: %i(show members subjects)
  before_action :check_course_access, only: %i(show members subjects)
  before_action :set_courses_page_class

  # GET /trainee/courses/:id
  def show
    redirect_to subjects_trainee_course_path @course
  end

  # GET /trainee/courses/:id/members
  def members
    @trainers = @course.supervisors.includes :user_courses
    @pagy, @trainees = pagy(@course.user_courses.trainees,
                            limit: Settings.pagination.course_members_per_page)
    @trainee_count = @pagy.count
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count
  end

  # GET /trainee/courses/:id/subjects
  def subjects
    @course_subjects = @course.course_subjects
                              .includes(
                                :tasks,
                                subject: {image_attachment: :blob},
                                user_subjects: [
                                  :user,
                                  {comments: :user}
                                ]
                              )
                              .ordered_by_position
    @subject_count = @course_subjects.count
    @trainee_count = @course.trainee_count
    @user_subjects_for_current_course = current_user.user_subjects
                                                    .for_course(@course)
                                                    .includes(USER_SJ_PRELOAD)
  end

  private

  def set_courses_page_class
    self.page_class = Settings.page_classes.courses
  end

  def load_course
    @course = Course.find_by id: params[:id]
    return if @course

    flash[:danger] = t(".course_not_found")
    redirect_to root_path
  end

  def check_course_access
    # Allow access if user is admin, supervisor of the course, or enrolled in
    # the course
    return if current_user.admin?
    return if @course.supervisors.include?(current_user)
    return if @course.users.include?(current_user)

    flash[:danger] = t(".access_denied")
    redirect_to root_path
  end
end
