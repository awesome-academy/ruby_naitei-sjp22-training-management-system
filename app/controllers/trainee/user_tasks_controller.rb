class Trainee::UserTasksController < Trainee::BaseController
  before_action :load_user_task, only: %i(
    update_document update_status update_spent_time destroy_document
  )
  before_action :load_course_and_subject_id, only: %i(
    update_document update_status update_spent_time destroy_document
  )

  # PATCH /trainee/user_tasks/:id/document
  def update_document
    if update_document?
      flash[:success] = t(".document_updated")
      make_subject_in_progress
    end
    safe_redirect_to_course_subject
  end

  # PATCH /trainee/user_tasks/:id/status
  def update_status
    if update_status?
      flash[:success] = t(".status_updated")
      make_subject_in_progress
    end
    safe_redirect_to_course_subject
  end

  # PATCH /trainee/user_tasks/:id/spent_time
  def update_spent_time
    if update_spent_time?
      make_subject_in_progress
      flash[:success] = t(".spent_time_updated")
    end
    safe_redirect_to_course_subject
  end

  # DELETE /trainee/user_tasks/:id/document
  def destroy_document
    flash[:success] = t(".document_destroyed") if destroy_document?
    safe_redirect_to_course_subject
  end

  private

  def load_user_task
    @user_task = current_user.user_tasks.find_or_create_by(
      task_id: params[:task_id], user_subject_id: params[:user_subject_id]
    ) do |user_task|
      user_task.status = :not_done
      user_task.spent_time = nil
    end
    attachments = @user_task.documents.attachments
    attachments.includes(:blob).load
  end

  def load_course_and_subject_id
    @course_id, @subject_id = extract_course_and_subject_id(@user_task)
    return if @course_id && @subject_id

    handle_invalid_course_or_subject
  end

  def handle_invalid_course_or_subject
    flash[:danger] = t(".cannot_do_this_task")
  end

  def safe_redirect_to_course_subject
    if @course_id && @subject_id
      redirect_to trainee_course_subject_path(@course_id, @subject_id)
    elsif @course_id
      redirect_to trainee_course_path(@course_id)
    else
      redirect_to root_path
    end
  end

  def extract_course_and_subject_id user_task
    user_subject = user_task&.user_subject
    course_subject = user_subject&.course_subject
    [course_subject&.course_id, course_subject&.subject_id]
  end

  def update_document?
    return true if params[:document].present? &&
                   @user_task.documents.attach(params[:document])

    flash[:danger] = t(".document_update_failed")
    false
  end

  def update_status?
    return false if params[:status].blank?

    new_status = if params[:status].to_i == Settings.user_task.status.done
                   :done
                 else
                   :not_done
                 end
    return true if @user_task.update(status: new_status)

    flash[:danger] = t(".status_update_failed")
    false
  end

  def update_spent_time?
    return true if params[:spent_time].present? &&
                   @user_task.update(spent_time: params[:spent_time])

    flash[:danger] = t(".spent_time_update_failed")
    false
  end

  def destroy_document?
    document = @user_task.documents.find_by(id: params[:document_id])
    return true if document&.purge

    flash[:danger] = t(".document_not_found")
    false
  end

  def make_subject_in_progress
    user_subject = @user_task.user_subject
    return unless user_subject
    return unless user_subject.not_started?

    unless user_subject.update(
      started_at: user_subject.started_at || Time.zone.today,
      status: :in_progress
    )
      flash[:danger] = t(".subject_in_progress_failed")
      return false
    end
    true
  end
end
