class StaticPagesController < ApplicationController
  # GET / (root)
  # GET /static_pages/home
  def home
    redirect_to admin_dashboards_path if manager?

    @q = Course.accessible_by(current_ability)
               .ordered_by_start_date
               .includes(:user)
               .ransack(params[:q])

    @pagy, @courses = pagy(@q.result(distinct: true))
  end
end
