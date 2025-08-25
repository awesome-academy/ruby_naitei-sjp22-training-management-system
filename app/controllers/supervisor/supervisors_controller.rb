class Supervisor::SupervisorsController < ApplicationController
  ERROR_ADD_TRAINERS_FAILED = "Failed to add trainers to course: %<message>s"
                              .freeze

  before_action :load_course
  before_action :load_supervisor, only: %i(destroy)
  authorize_resource class: "CourseSupervisor"

  # DELETE /supervisor/courses/:course_id/supervisors/:id
  def destroy
    if @course.supervisors.destroy(@supervisor)
      flash[:success] = I18n.t("courses.destroy_supervisor.success")
    else
      flash[:danger] =
        @course.course_supervisors.errors[:base].presence&.first
    end
    redirect_back fallback_location: members_supervisor_course_path(@course)
  end

  # POST /supervisor/courses/:course_id/supervisors
  def create
    user_ids = Array(params[:user_ids]).map(&:to_i).uniq
    trainers = User.where(id: user_ids, role: :supervisor)

    result = add_trainers_to_course(trainers)

    if result[:success]
      render json: {added: result[:added_count]}, status: :ok
    else
      render json: {error: result[:error_message]},
             status: :unprocessable_entity
    end
  end

  private

  def add_trainers_to_course trainers
    added_count = 0
    error_message = nil

    ActiveRecord::Base.transaction do
      trainers.find_each do |trainer|
        unless @course.supervisors.exists?(trainer.id)
          course_supervisor = @course.course_supervisors
                                     .build(user_id: trainer.id)
          if course_supervisor.save
            added_count += 1
          else
            error_message = t(".failed_to_add_trainer", name: trainer.name)
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    if error_message
      {success: false, error_message: error_message}
    else
      {success: true, added_count: added_count}
    end
  rescue StandardError => e
    Rails.logger.error(format(ERROR_ADD_TRAINERS_FAILED, message: e.message))
    {success: false, error_message: t(".unexpected_error")}
  end

  def load_course
    @course = Course.find_by(id: params[:course_id])
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def load_supervisor
    @supervisor = @course.supervisors.find_by(id: params[:id])
    return if @supervisor

    flash[:danger] = I18n.t("courses.errors.supervisor_not_found")
    redirect_back fallback_location: members_supervisor_course_path(@course)
  end
end
