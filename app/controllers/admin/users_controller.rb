class Admin::UsersController < Admin::BaseController
  before_action :load_supervisors, only: %i(index)
  before_action :load_courses, only: %i(index)
  before_action :load_trainees, only: %i(new_supervisor add_role_supervisor)
  before_action :load_supervisor,
                only: %i(update_status show update delete_user_course)
  before_action :set_css_class, only: %i(index show)
  before_action :load_user_course, only: %i(delete_user_course)
  authorize_resource

  # GET /admin/users
  def index
    @pagy, @supervisors = pagy(@user_supervisors)
  end

  # GET /admin/users/new_supervisor
  def new_supervisor; end

  # PATCH /admin/users/:id/update_status
  def update_status
    flash[:success] = t(".update_success") if update_status?

    redirect_to session.delete(:forwarding_url) || admin_users_path
  end

  # GET /admin/users/:id
  def show
    @q = @user_supervisor.supervised_courses
                         .ransack(params[:q])
    @supervisor_courses = @q.result(distinct: true)
                            .includes(:users)
                            .recent
    @pagy, @supervisor_courses = pagy(@supervisor_courses)
  end

  # PATCH /admin/users/:id
  def update
    if @user_supervisor.update(user_params)
      flash[:success] = t(".update_success")
      redirect_to admin_user_path(@user_supervisor)
    else
      flash[:danger] = t(".update_failed")
      render :show
    end
  end

  # DELETE /admin/users/:id
  def delete_user_course
    flash[:success] = t(".delete_success") if handle_delete_user_course

    redirect_to admin_user_path(@user_supervisor)
  end

  # PATCH /admin/users/add_role_supervisor
  def add_role_supervisor
    flash[:success] = t(".add_success") if handle_add_role_supervisor?

    redirect_to new_supervisor_admin_users_path
  end

  private

  def load_trainees
    @q = User.trainee.ransack(params[:q])
    @user_trainees = @q.result(distinct: true).recent
  end

  def load_user_course
    @user_course = @user_supervisor.course_supervisors
                                   .find_by(course_id: params[:course_id])
    return if @user_course

    flash[:danger] = t(".course_not_found")
    redirect_to admin_user_path(@user_supervisor)
  end

  def handle_delete_user_course
    return true if @user_course.destroy

    flash[:danger] = t(".delete_failed")
    false
  end

  def user_params
    params.require(:user).permit(User::PERMITTED_UPDATE_ATTRIBUTES)
  end

  def load_supervisors
    @q = User.supervisor.ransack(params[:q])
    @user_supervisors = @q.result(distinct: true).recent
  end

  def load_courses
    @courses = Course.recent
  end

  def load_supervisor
    @user_supervisor = User.find_by(id: params[:id])
    return if @user_supervisor

    flash[:danger] = t(".supervisor.not_found")
    redirect_to admin_users_path
  end

  def update_status?
    @user_supervisor.update(confirmed_at: params[:confirmed_at])
    true
  end

  def toggle_supervisors_status supervisors
    updated_count = 0
    supervisors.each do |supervisor|
      new_status = supervisor.confirmed_at? ? false : true
      if supervisor.update(confirmed_at: new_status ? Time.current : nil)
        updated_count += 1
      end
    end
    updated_count
  end

  def flash_no_selection
    flash[:danger] = t(".supervisor_no_selection")
    redirect_to admin_users_path
  end

  def set_css_class
    @page_class = Settings.page_classes.admin_users
  end

  def handle_add_role_supervisor?
    return false if params[:supervisor_ids].blank?

    begin
      @user_trainees.where(id: params[:supervisor_ids])
                    .update_all(role: :supervisor)
    rescue StandardError
      flash[:danger] = t(".add_failed")
      false
    end
    true
  end
end
