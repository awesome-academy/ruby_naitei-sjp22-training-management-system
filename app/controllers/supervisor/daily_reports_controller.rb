class Supervisor::DailyReportsController < Supervisor::BaseController
  # GET supervisor/daily_reports
  authorize_resource
  def index
    supervised_course_ids = current_user.supervised_courses.pluck(:id)

    all_reports = DailyReport.recent.includes(DailyReport::EAGER_LOADING_PARAMS)
                             .by_course(supervised_course_ids)
                             .by_course_filter(params[:course_id])
                             .on_day(params[:filter_date])
                             .by_user(params[:user_id])

    @pagy, @daily_reports = pagy(all_reports)
  end

  # GET supervisor/daily_reports/:id
  def show
    @daily_report = DailyReport.submitted.find_by(id: params[:id],
                                                  course_id: current_user
                                                  .supervised_courses
                                                  .pluck(:id))
    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to supervisor_daily_reports_path
  end
end
