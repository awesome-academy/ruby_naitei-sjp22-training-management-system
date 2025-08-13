class Supervisor::CoursesController < Supervisor::BaseController
  include Supervisor::CoursesHelper

  before_action :require_manager
  skip_before_action :check_supervisor_role

  # GET /admin/courses
  def index
    @statuses = build_statuses

    courses_query = Course.includes(:user)
                          .with_counts
                          .filter_by_params(params)
                          .ordered_by_start_date

    @pagy, @courses = pagy courses_query, limit: Settings.ui.items_per_page
  end
end
