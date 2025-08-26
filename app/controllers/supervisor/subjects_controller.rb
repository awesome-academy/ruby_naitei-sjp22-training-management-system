class Supervisor::SubjectsController < Supervisor::BaseController
  before_action :load_subject,
                only: %i(show edit update destroy_tasks destroy)
  authorize_resource

  # GET /supervisor/subjects
  def index
    @pagy, @subjects = pagy Subject.includes(:tasks)
                                   .recent
                                   .search_by_name(params[:search]),
                            items: Settings.ui.items_per_page
  end

  # GET /supervisor/subjects/:id
  def show
    @tasks = @subject.tasks.ordered_by_name
  end

  # GET /supervisor/subjects/new
  def new
    @subject = Subject.new
  end

  # POST /supervisor/subjects
  def create
    @subject = Subject.new(subject_params_for_create)
    if @subject.save
      flash[:success] = t(".subject_created")
      redirect_to supervisor_subjects_path
    else
      flash[:danger] = t(".create_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /supervisor/subjects/:id/edit
  def edit; end

  # PATCH/PUT /supervisor/subjects/:id
  def update
    if @subject.update(subject_params_for_update)
      flash[:success] = t(".update_success", subject_name: @subject.name)
    else
      flash[:danger] = @subject.errors.full_messages.join(", ")
    end
    redirect_to supervisor_subject_path(@subject)
  end

  # DELETE /supervisor/subjects/:id
  def destroy
    if @subject.destroy
      flash[:success] = t(".subject_deleted")
    else
      flash[:danger] = t(".delete_failed")
    end
    redirect_to supervisor_subjects_path
  end

  # DELETE /supervisor/subjects/:id/destroy_tasks
  def destroy_tasks
    task_ids = params[:task_ids] || []
    if task_ids.any?
      destroyed_count = @subject.tasks.where(id: task_ids).destroy_all.size
      flash[:success] = t(".n_tasks_deleted", count: destroyed_count)
    else
      flash[:alert] = t(".no_tasks_to_delete")
    end
    redirect_to edit_supervisor_subject_path(@subject)
  end

  private

  def subject_params_for_create
    params.require(:subject).permit Subject::SUBJECT_PERMITTED_PARAMS_CREATE
  end

  def subject_params_for_update
    params.require(:subject).permit Subject::SUBJECT_PERMITTED_PARAMS_UPDATE
  end

  def load_subject
    @subject = Subject.includes(:tasks).find_by(id: params[:id])
    return if @subject

    flash[:danger] = t("not_found_subject")
    redirect_to supervisor_subjects_path
  end
end
