class Admin::DailyReportsController < Admin::BaseController
  before_action :load_daily_report, only: :show
  authorize_resource

  # GET /daily_reports
  def index
    @q = DailyReport.recent.includes(DailyReport::EAGER_LOADING_PARAMS).ransack(params[:q])
    @pagy, @daily_reports = pagy(@q.result(distinct: true))
  end

  # GET /daily_reports/:id
  def show; end

  private

  def load_daily_report
    @daily_report = DailyReport.submitted.find_by(id: params[:id])
    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to admin_daily_reports_path
  end
end
