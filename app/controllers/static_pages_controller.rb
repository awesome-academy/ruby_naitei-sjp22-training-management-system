class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  # GET / (root)
  # GET /static_pages/home
  def home
    redirect_to admin_dashboards_path if manager?

    return unless user_signed_in?

    @pagy, @courses = pagy(
      current_user.courses
                  .by_status(params[:status])
                  .ordered_by_start_date
                  .includes(:user)
                  .with_attached_image,
      items: Settings.ui.items_per_page
    )
  end

  private
  def trainee_dashboard
    @pagy, @courses = pagy(
      current_user.courses
                  .by_status(params[:status])
                  .ordered_by_start_date
                  .includes(:user)
                  .with_attached_image,
      items: Settings.ui.items_per_page
    )
  end
end
