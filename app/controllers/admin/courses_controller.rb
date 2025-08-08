class Admin::CoursesController < AdminController
  before_action :set_course, only: %i(new create destroy)

  def index
    @statuses = Course.statuses.keys.map {|status| [status.humanize, status]}

    @pagy, @courses = pagy(
      Course.includes(:user)
            .with_counts
            .search_by_name(params[:search])
            .by_status(params[:status])
            .ordered_by_start_date,
      items: 10
    )
  end

  def new; end

  def create; end

  def destroy; end

  private
  def set_course
    @course = Course.find(params[:id])
  end
end
