class Admin::DailyReportsController < Admin::BaseController
  authorize_resource

  # GET /daily_reports
  def index
    all_reports = DailyReport.recent.includes(DailyReport::EAGER_LOADING_PARAMS)
                             .by_course_filter(params[:course_id])
                             .on_day(params[:filter_date])
                             .by_user(params[:user_id])

    @pagy, @daily_reports = pagy(all_reports)
  end

  # GET /daily_reports/:id
  def show
    @daily_report = DailyReport.submitted.find_by(id: params[:id])

    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to admin_daily_reports_path
  end
end
