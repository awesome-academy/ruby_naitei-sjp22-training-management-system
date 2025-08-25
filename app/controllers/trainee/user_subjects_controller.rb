class Trainee::UserSubjectsController < Trainee::BaseController
  before_action :load_user_subject, only: %i(update)
  authorize_resource

  USER_SUBJECT_PARAMS = %i(started_at completed_at status).freeze

  # PATCH /trainee/user_subjects/:id
  def update
    normalize_finish_params!
    success = update?
    flash[:success] = t(".update_success") if success

    course_id = @user_subject.course_subject&.course_id
    subject_id = @user_subject.course_subject&.subject_id
    if course_id && subject_id
      redirect_to trainee_course_subject_path(course_id, subject_id)
    else
      redirect_back fallback_location: trainee_courses_path
    end
  end

  private

  def user_subject_params
    params.require(:user_subject)
          .permit(USER_SUBJECT_PARAMS)
  end

  def normalize_finish_params!
    user_subject_hash = params[:user_subject]
    return unless user_subject_hash

    started_at = user_subject_hash[:started_at].presence || Date.current
    completed_at = user_subject_hash[:completed_at].presence || Date.current

    user_subject_hash[:started_at] = started_at
    user_subject_hash[:completed_at] = completed_at

    # Derive enum status from dates
    derived_status = @user_subject.compute_finish_status(completed_at)
    user_subject_hash[:status] = UserSubject.statuses[derived_status]
  end

  def load_user_subject
    @user_subject = UserSubject.find_by(id: params[:id])
    return if @user_subject

    flash[:danger] = t(".subject_not_found")
    redirect_to trainee_course_path
  end

  def update?
    return true if @user_subject.update(user_subject_params)

    flash[:danger] = t(".update_failed")
    false
  end
end
