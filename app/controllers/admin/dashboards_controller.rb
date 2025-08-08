class Admin::DashboardsController < ApplicationController
  # GET /admin/dashboards
  def index
    @overview_stats = {
      trainers: User.supervisor.count,
      trainees: User.trainee.count,
      active_courses: Course.in_progress.count,
      completion_rate: calculate_completion_rate
    }

    active_courses_query = active_courses?

    @pagy, @courses = pagy(active_courses_query,
                           limit: Settings.ui.items_per_page)
  end

  private

  def calculate_completion_rate
    total = Course.group(:status).count.values.sum
    return "#{Settings.completion_rate.zero}%" if total.zero?

    finished = Course.finished.count
    rate = (finished.to_f / total * Settings.percentage).round
    "#{rate}%"
  end

  def active_courses?
    Course.in_progress
          .includes(:user)
          .with_counts
          .search_by_name(params[:search])
          .order(created_at: :desc)
  end
end
