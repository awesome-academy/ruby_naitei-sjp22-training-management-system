class Supervisor::DailyReportsController < Supervisor::BaseController
  before_action :load_daily_report, only: :show
  authorize_resource

  # GET supervisor/daily_reports
  def index
    all_reports = DailyReport.accessible_by(current_ability)
                             .recent.includes(DailyReport::EAGER_LOADING_PARAMS)
                             .by_course_filter(params[:course_id])
                             .on_day(params[:filter_date])
                             .by_user(params[:user_id])

    @pagy, @daily_reports = pagy(all_reports)
  end

  # GET supervisor/daily_reports/:id
  def show; end

  private

  def load_daily_report
    @daily_report = DailyReport.submitted.find_by(id: params[:id])
    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to supervisor_daily_reports_path
  end
end
