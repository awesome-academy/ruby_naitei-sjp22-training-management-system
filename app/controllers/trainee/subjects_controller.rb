class Trainee::SubjectsController < Trainee::BaseController
  before_action :load_course, only: %i(show)
  before_action :load_subject, only: %i(show)
  before_action :load_course_subject, only: %i(show)
  before_action :ensure_user_enrollments, only: %i(show)
  before_action :load_tasks, only: %i(show)
  before_action :load_comments, only: %i(show)
  authorize_resource

  # GET /trainee/courses/:course_id/subjects/:id
  def show; end

  private

  def load_course
    @course = Course.find_by(id: params[:course_id])
    return if @course

    flash[:danger] = t(".course_not_found")
    redirect_to trainee_course_path(course_id: params[:course_id])
  end

  def load_subject
    @subject = @course.subjects.find_by(id: params[:id])
    return if @subject

    flash[:danger] = t(".subject_not_found")
    redirect_to trainee_course_path(course_id: @course.id)
  end

  def load_tasks
    @tasks = if @course_subject
               @course_subject
                 .tasks
                 .includes(user_tasks: {documents_attachments: :blob})
             else
               []
             end
  end

  def load_comments
    @comments = @user_subject&.comments&.includes(:user) || []
  end

  def create_missing_user_tasks
    @course_subject.tasks.find_each do |task|
      next if @user_subject.user_tasks.exists?(task: task)

      @user_subject.user_tasks.create!(
        user: current_user,
        task: task,
        status: Settings.user_task.status.not_done
      )
    end
  end

  def load_course_subject
    @course_subject = CourseSubject.find_by(course_id: @course.id,
                                            subject_id: @subject.id)
  end

  def ensure_user_enrollments
    @user_course = UserCourse.find_by(course_id: @course.id)
    return unless @user_course && @course_subject

    ActiveRecord::Base.transaction do
      find_or_create_user_subject!
      create_missing_user_tasks if @user_subject
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error(
      "ensure_user_enrollments failed: #{e.class}: #{e.message}"
    )
    flash[:danger] = t(".cannot_initialize_subject")
    redirect_back fallback_location: trainee_courses_path
  end

  def find_or_create_user_subject!
    @user_subject = UserSubject.find_or_create_by!(
      user_course_id: @user_course.id,
      course_subject_id: @course_subject.id
    ) do |user_subject|
      user_subject.status = Settings.user_subject.status.not_started
    end
  end
end
