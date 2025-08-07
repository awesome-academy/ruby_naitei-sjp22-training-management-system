class Trainee::UserTasksController < TraineeController
  before_action :load_user_task,
                only: %i(update_document update_status update_spent_time
destroy_document)

  # PATCH /trainee/user_tasks/:id/document
  def update_document
    flash[:success] = t(".document_updated") if handle_update_document

    redirect_to trainee_course_subject_path(@course_id, @subject_id)
  end

  # PATCH /trainee/user_tasks/:id/status
  def update_status
    flash[:success] = t(".status_updated") if handle_update_status
    redirect_to trainee_course_subject_path(@course_id, @subject_id)
  end

  # PATCH /trainee/user_tasks/:id/spent_time
  def update_spent_time
    flash[:success] = t(".spent_time_updated") if handle_update_spent_time

    redirect_to trainee_course_subject_path(@course_id, @subject_id)
  end

  # Delete /trainee/user_tasks/:id/document
  def destroy_document
    flash[:success] = t(".document_destroyed") if handle_destroy_document

    redirect_to trainee_course_subject_path(@course_id, @subject_id)
  end

  private

  def load_user_task
    @user_task = current_user.user_tasks.find_or_create_by(
      task_id: params[:task_id], user_subject_id: params[:user_subject_id]
    ) do |user_task|
      user_task.status = Settings.user_task.status.not_done
      user_task.spent_time = nil
    end
    get_course_and_subject_id
  end

  def get_course_and_subject_id
    @course_id, @subject_id = extract_course_and_subject_id(@user_task)
    return if @course_id && @subject_id

    handle_invalid_course_or_subject
  end

  def handle_invalid_course_or_subject
    flash[:danger] = t(".cannot_do_this_task")
    redirect_to trainee_courses_path
  end

  def extract_course_and_subject_id user_task
    user_subject = user_task&.user_subject
    course_subject = user_subject&.course_subject
    [course_subject&.course_id, course_subject&.subject_id]
  end

  def handle_update_document
    return true if params[:document].present? &&
                   @user_task.documents.attach(params[:document])

    flash[:danger] = t(".document_not_attached")
    false
  end

  def handle_update_status
    return true if params[:status].present? &&
                   @user_task.update(status: params[:status])

    flash[:danger] = t(".status_not_updated")
    false
  end

  def handle_update_spent_time
    return true if params[:spent_time].present? &&
                   @user_task.update(spent_time: params[:spent_time])

    flash[:danger] = t(".spent_time_not_updated")
    false
  end

  def handle_destroy_document
    document = @user_task.documents.find_by(id: params[:document_id])
    return true if document&.purge

    flash[:danger] = t(".document_not_found")
    false
  end
end
