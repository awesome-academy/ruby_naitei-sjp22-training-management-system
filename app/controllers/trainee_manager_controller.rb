class TraineeManagerController < ApplicationController
  before_action :check_permissions, only: %i(index show update_status bulk_deactivate)
  before_action :get_courses, only: %i(index)
  before_action :get_trainees, only: %i(index)
  before_action :load_trainee, only: %i(update_status)
  before_action :set_css_class, only: %i(index)

  def index
    @pagy, @trainees = pagy(@user_trainees)
  end
  
  def show; end

  def update_status
     flash[:success] = t(".trainee.update_success") if handle_update_status

     redirect_to trainee_manager_index_path
  end

  def bulk_deactivate
    handle_bulk_deactivate
    redirect_to trainee_manager_index_path
  end

  private 

  def get_trainees
    @user_trainees = User.filter_by_role(Settings.user.roles.trainee)

    if params[:search].present?
      @user_trainees = @user_trainees.filter_by_name(params[:search])
    end

    if params[:status].present?
      @user_trainees = @user_trainees.filter_by_status(params[:status])
    end

    if params[:course].present?
      @user_trainees = @user_trainees.joins(:courses)
                           .where(courses: { id: params[:course] })
    end
    
  end

  def get_courses
    @courses = Course.resent
  end

  def load_trainee 
    @user_trainee = User.find_by(id: params[:id])

    return if @user_trainee
    flash[:danger] = t(".trainee.not_found")
    redirect_to trainee_manager_index_path
  end

  def handle_update_status
    return true if params[:activated].present? && @user_trainee.update(activated: params[:activated])

    flash[:danger] = t(".trainee.update_failed")
    false
  end

  def handle_bulk_deactivate
    trainee_ids = params[:trainee_ids]
    
    if trainee_ids.blank?
      flash[:danger] = t(".trainee_no_selection")
      return
    end

    trainees = User.where(id: trainee_ids)
    deactivated_count = 0
    
    trainees.each do |trainee|
      deactivated_count += 1 if trainee.update(activated: :inactive)
    end

    if deactivated_count > 0
      flash[:success] = t(".bulk_deactivate_success", count: deactivated_count)
    else
      flash[:danger] = t(".bulk_deactivate_failed")
    end
  end
  
  def set_css_class
    @page_class = Settings.page_classes.trainee_manager
  end

  def check_permissions
    return if !current_user.trainee?
    flash[:danger] = t(".unauthorized_access")
    redirect_to root_path
  end
end
