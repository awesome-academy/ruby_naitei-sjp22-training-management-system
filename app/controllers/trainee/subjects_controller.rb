class Trainee::SubjectsController < Trainee::BaseController
  before_action :load_course, only: %i(show)
  before_action :load_subject, only: %i(show)
  before_action :load_tasks, only: %i(show)
  before_action :load_course_subject, only: %i(show)
  before_action :load_comments, only: %i(show)

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
    @tasks = CourseSubject.find_by(course_id: @course.id,
                                   subject_id: @subject.id)&.tasks || []
  end

  def load_comments
    @user_course = current_user.user_courses.find_by(course_id: @course.id)
    @user_subject = current_user.user_subjects.find_by(
      user_course_id: @user_course.id, course_subject_id: @course_subject.id
    )
    @comments = @user_subject&.comments&.includes(:user) || []
  end

  def load_course_subject
    @course_subject = CourseSubject.find_by(course_id: @course.id,
                                            subject_id: @subject.id)
  end
end
