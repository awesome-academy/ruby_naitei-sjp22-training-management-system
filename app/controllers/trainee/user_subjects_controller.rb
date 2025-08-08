class Trainee::UserSubjectsController < TraineeController
  before_action :find_user_subject_by_id, only: %i(update)

  USER_SUBJECT_PARAMS = %i(started_at completed_at status).freeze

  # PATCH /trainee/user_subjects/:id
  def update
    flash[:success] = t(".subject_updated") if handle_update

    redirect_to trainee_courses_path
  end

  private

  def user_subject_params
    params.require(:user_subject)
          .permit(USER_SUBJECT_PARAMS).tap do |whitelisted|
      whitelisted[:status] = whitelisted[:status].to_i if whitelisted[:status]
    end
  end

  def find_user_subject_by_id
    @user_subject = current_user.user_subjects.find_by(id: params[:id])
    return if @user_subject

    flash[:danger] = t(".subject_not_found")
    redirect_to trainee_courses_path
  end

  def handle_update
    return true if @user_subject.update(user_subject_params)

    flash[:danger] = t(".update_failed")
    false
  end
end
