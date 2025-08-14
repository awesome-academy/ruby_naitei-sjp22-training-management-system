class Supervisor::SubjectsController < Supervisor::BaseController
  skip_before_action :check_supervisor_role
  before_action :load_subject

  def show
    @tasks = CourseSubject.find_by(subject_id: params[:id])&.tasks || []
  end

  private

  def load_subject
    @subject = Subject.find params[:id]
  end
end
