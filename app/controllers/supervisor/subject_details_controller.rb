class Supervisor::SubjectDetailsController < Supervisor::BaseController
  USER_SUBJECTS_INCLUDES = [
    {user: [:image_attachment]},
      {comments: [:user]},
      {user_tasks: [:task]}
  ].freeze
  before_action :load_course_subject,
                only: %i(show create_task update_task update_score
                create_comment update_comment destroy_comment)
  before_action :load_subject, only: %i(show)
  before_action :load_subject_tasks, only: %i(show)
  before_action :load_user_subjects,
                only: %i(show update_score create_comment update_comment
destroy_comment)
  before_action :load_task, only: %i(update_task)
  before_action :load_user_subject,
                only: %i(create_comment update_comment destroy_comment
update_score show)
  before_action :user_tasks_size, only: %i(show)
  before_action :load_comment, only: %i(update_comment destroy_comment)
  before_action :set_css_class, only: %i(show)
  before_action :require_manager
  # GET /admin/courses/:course_id/subjects/:id
  def show; end

  # POST /admin/courses/:course_id/subjects/:id/create_task
  def create_task
    flash[:success] = t(".create_success") if handle_create_task?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  # PATCH /admin/courses/:course_id/subjects/:id/update_task
  def update_task
    flash[:success] = t(".update_success") if handle_update_task?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  # PATCH /admin/courses/:course_id/subjects/:id/update_score
  def update_score
    flash[:success] = t(".update_success") if handle_update_score?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  # POST /admin/courses/:course_id/subjects/:id/create_comment
  def create_comment
    flash[:success] = t(".create_success") if handle_create_comment?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  # DELETE /admin/courses/:course_id/subjects/:id/destroy_comment
  def destroy_comment
    flash[:success] = t(".destroy_success") if handle_destroy_comment?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  # PATCH /admin/courses/:course_id/subjects/:id/update_comment
  def update_comment
    flash[:success] = t(".update_success") if handle_update_comment?

    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  private

  def load_course_subject
    @course_subject = CourseSubject.with_deleted.find_by(
      course_id: params[:course_id], subject_id: params[:id]
    )
    return if @course_subject

    flash[:danger] = t(".course_subject.not_found")
    redirect_to admin_courses_path
  end

  def load_subject
    @subject = @course_subject.subject
    return if @subject

    flash[:danger] = t(".subject.not_found")
    redirect_to admin_courses_path
  end

  def load_subject_tasks
    @subject_tasks = @course_subject.tasks.includes(user_tasks:
    [:documents_attachments])
  end

  def load_user_subjects
    @user_subjects_query = @course_subject.user_subjects
                                          .includes(USER_SUBJECTS_INCLUDES)
    @pagy, @user_subjects = pagy(@user_subjects_query)
  end

  def task_params
    params.require(:task).permit(:name)
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def load_task
    @task = @course_subject.tasks.find_by(id: params[:task_id])
    return if @task

    flash[:danger] = t(".task.not_found")
    redirect_to admin_courses_path
  end

  def handle_update_score?
    return true if @user_subject.update(score: params[:score])

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_update_task?
    return true if @task.update(task_params)

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_create_task?
    is_first_task = session[:count_create_task].nil? ||
                    session.delete(:count_create_task).zero?
    task = @course_subject.tasks.build(task_params)
    return false unless task.save

    reset_all_user_subjects_completion if is_first_task
    true
  rescue StandardError
    flash[:danger] = t(".create_failed")
    false
  end

  def handle_create_comment?
    comment = @user_subject.comments.build(comment_params)
    comment.user = current_user
    return true if comment.save

    flash[:danger] = t(".create_failed")
    false
  end

  def handle_update_comment?
    return true if @comment&.update(comment_params)

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_destroy_comment?
    return true if @comment&.destroy

    flash[:danger] = t(".destroy_failed")
    false
  end

  def load_user_subject
    if params[:user_id].present?
      @user_subject = @user_subjects.find_by(user_id: params[:user_id])
    end

    @user_subject = @user_subjects_query.first if @user_subject.nil?

    return if @user_subject

    flash[:danger] = t(".user_subject.not_found")
    redirect_to admin_courses_path
  end

  def user_tasks_size
    @subject_tasks_count = @subject_tasks.count
  end

  def load_comment
    @comment = @user_subject.comments.find_by(id: params[:comment_id])
    return if @comment

    flash[:danger] = t(".comment.not_found")
    redirect_to supervisor_course_subject_detail_path(@course_subject.course,
                                                      @course_subject.subject)
  end

  def set_css_class
    @page_class = Settings.page_classes.admin_subjects
  end

  def reset_all_user_subjects_completion
    @course_subject.user_subjects.update_all(
      completed_at: nil,
      started_at: nil,
      status: :in_progress
    )
  end
end
