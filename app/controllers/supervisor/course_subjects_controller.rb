class Supervisor::CourseSubjectsController < Supervisor::BaseController
  before_action :load_course
  before_action :load_course_subject, only: %i(destroy finish)
  authorize_resource

  # DELETE /supervisor/courses/:course_id/course_subjects/:id
  def destroy
    if @course_subject.destroy
      flash[:success] = I18n.t("courses.destroy_course_subject.success")
    else
      flash[:danger] = I18n.t("courses.destroy_course_subject.failed")
    end
    redirect_back fallback_location: subjects_fallback_path
  end

  # POST /supervisor/courses/:course_id/course_subjects/:id/finish
  def finish
    if @course_subject.user_subjects.update_all(
      status: UserSubject.statuses[:finished_ontime], completed_at: Time.current
    )
      flash[:success] = I18n.t("courses.finish_course_subject.success")
    else
      flash[:danger] = I18n.t("courses.finish_course_subject.failed")
    end
    redirect_back fallback_location: subjects_fallback_path
  end

  private

  def load_course
    @course = Course.find_by(id: params[:course_id])
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def load_course_subject
    @course_subject = @course.course_subjects
                             .includes(
                               {tasks: :user_tasks},
                               {user_subjects: [:comments, :user_tasks]}
                             )
                             .find_by(id: params[:id])
    return if @course_subject

    flash[:danger] = I18n.t("courses.errors.course_subject_not_found")
    redirect_back fallback_location: subjects_fallback_path
  end

  def subjects_fallback_path
    subjects_supervisor_course_path(@course)
  end
end
