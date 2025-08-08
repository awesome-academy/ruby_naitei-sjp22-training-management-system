class CoursesController < ApplicationController
  EAGER_LOAD_USER_COURSE = {
    user_subjects: {user_tasks: :documents_attachments}
  }.freeze

  EAGER_LOAD_COURSE_SUBJECT = {
    tasks: {user_tasks: :documents_attachments},
    user_subjects: [:comments, {user_tasks: :documents_attachments}]
  }.freeze

  EAGER_LOAD_SUBJECTS = [
    :subject,
    :tasks,
    {user_subjects: [:user, :comments]}
  ].freeze

  EAGER_LOAD_USER_SUBJECTS = [
    :comments,
    {user_tasks: :documents_attachments}
  ].freeze

  before_action :set_scope
  before_action :find_course, only: %i(
    show
    members
    subjects
    supervisors
    destroy_user_course
    destroy_supervisor
    destroy_course_subject
    finish_course_subject
    leave
  )
  before_action :authorize_by_scope!
  before_action :set_courses_page_class

  # GET /admin/courses/:id or /supervisor/courses/:id
  def show
    if admin_scope?
      redirect_to members_admin_course_path @course
    else
      redirect_to subjects_supervisor_course_path @course
    end
  end

  # GET /admin(courses)/:id/members or /supervisor/courses/:id/members
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

  # GET /admin(courses)/:id/subjects or /supervisor/courses/:id/subjects
  def subjects
    @subjects = @course.course_subjects.includes(EAGER_LOAD_SUBJECTS)
    @subject_count = @subjects.count
    @trainee_count = @course.trainees_count
    @trainer_count = @course.supervisors.count

    render template: Settings.templates.courses.subjects
  end

  # GET /admin/courses/:id/supervisors
  def supervisors
    @trainers = @course.supervisors.includes :user_courses
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count
    @trainee_count = @course.trainees_count
  end

  # DELETE
  # /admin|supervisor/courses/:id/user_courses/:id
  def destroy_user_course
    user_course = @course.user_courses
                         .includes(EAGER_LOAD_USER_COURSE)
                         .find(params[:user_course_id])

    user_course.user_subjects.includes(EAGER_LOAD_USER_SUBJECTS).load

    if user_course.destroy
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failed")
    end
    redirect_back fallback_location: members_fallback_path
  end

  # DELETE /admin/courses/:id/supervisors/:id
  def destroy_supervisor
    supervisor = @course.supervisors.find(params[:supervisor_id])
    if @course.supervisors.destroy(supervisor)
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failed")
    end
    redirect_back fallback_location: members_fallback_path
  end

  # DELETE /admin|supervisor/courses/:id/course_subjects/:id
  def destroy_course_subject
    course_subject = @course.course_subjects
                            .includes(EAGER_LOAD_COURSE_SUBJECT)
                            .find(params[:course_subject_id])
    if course_subject.destroy
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failed")
    end
    redirect_back fallback_location: subjects_fallback_path
  end

  # POST
  # /admin|supervisor/courses/:id/course_subjects/:id/finish
  def finish_course_subject
    course_subject = @course.course_subjects.find(params[:course_subject_id])
    if course_subject.user_subjects.update_all(
      status: UserSubject.statuses[:finished_ontime], completed_at: Time.current
    )
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failed")
    end
    redirect_back fallback_location: subjects_fallback_path
  end

  # DELETE /supervisor/courses/:id/leave
  def leave
    if @course.supervisors.count <= 1
      flash[:danger] = t(".must_have_another_supervisor")
      return redirect_back(fallback_location: members_fallback_path)
    end

    @course.supervisors.destroy(current_user)
    flash[:success] = t(".success")
    redirect_to root_path
  end

  private

  def set_scope
    @scope = if request.path.include?("/admin/")
               Settings.scope.admin
             else
               Settings.scope.supervisor
             end
  end

  def admin_scope?
    @scope == Settings.scope.admin
  end

  def set_courses_page_class
    self.page_class = if admin_scope?
                        Settings.page_classes.admin_courses
                      else
                        Settings.page_classes.courses
                      end
  end

  def find_course
    @course = Course.find_by id: params[:id]
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def authorize_by_scope!
    return if action_name.blank?

    if admin_scope?
      authorize_admin!
    else
      authorize_supervisor!
    end
  end

  def authorize_admin!
    return if current_user&.admin?

    flash[:danger] = I18n.t("messages.permission_denied")
    redirect_to root_path
  end

  def authorize_supervisor!
    return if current_user&.admin?

    course = ensure_course_present!
    return unless course

    return if allowed_for_supervisor?(course)

    flash[:danger] = I18n.t("courses.errors.access_denied")
    redirect_to root_path
  end

  def ensure_course_present!
    course = @course || Course.find_by(id: params[:id])
    return course if course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
    nil
  end

  def allowed_for_supervisor? course
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

  def members_fallback_path
    return members_admin_course_path(@course) if admin_scope?

    members_supervisor_course_path(@course)
  end

  def subjects_fallback_path
    return subjects_admin_course_path(@course) if admin_scope?

    subjects_supervisor_course_path(@course)
  end
end
