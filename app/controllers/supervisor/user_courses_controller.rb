class Supervisor::UserCoursesController < Supervisor::BaseController
  before_action :load_course
  before_action :load_user_course, only: %i(destroy)
  authorize_resource

  # DELETE /supervisor/courses/:course_id/user_courses/:id
  def destroy
    if @user_course.destroy
      flash[:success] = I18n.t("courses.destroy_user_course.success")
    else
      flash[:danger] = I18n.t("courses.destroy_user_course.failed")
    end

    redirect_back fallback_location: members_fallback_path
  end

  # POST /supervisor/courses/:course_id/user_courses
  def create
    user_ids = Array(params[:user_ids]).map(&:to_i).uniq
    trainees = User.where(id: user_ids, role: :trainee)

    result = add_trainees_to_course(trainees)

    if result[:success]
      render json: {added: result[:created_count]}, status: :ok
    else
      render json: {error: result[:error_message]},
             status: :unprocessable_entity
    end
  end

  private

  def add_trainees_to_course trainees
    created_count = 0
    error_message = nil

    ActiveRecord::Base.transaction do
      trainees.find_each do |trainee|
        user_course = @course.user_courses
                             .find_or_initialize_by(user_id: trainee.id)
        if user_course.new_record?
          user_course.joined_at = Time.current
          if user_course.save
            created_count += 1
          else
            error_message = t(".failed_to_add_trainee", name: trainee.name)
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    if error_message
      {success: false, error_message: error_message}
    else
      {success: true, created_count: created_count}
    end
  rescue StandardError => e
    Rails.logger.error("Failed to add trainees to course: #{e.message}")
    {success: false, error_message: t(".unexpected_error")}
  end

  def load_course
    @course = Course.find_by(id: params[:course_id])
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def load_user_course
    @user_course = @course.user_courses
                          .includes(user_subjects: [
                                      :comments,
        {user_tasks: :documents_attachments}
                                    ])
                          .find_by(id: params[:id])
    return if @user_course

    flash[:danger] = I18n.t("courses.errors.user_course_not_found")
    redirect_back fallback_location: members_fallback_path
  end

  def members_fallback_path
    members_supervisor_course_path(@course)
  end
end
