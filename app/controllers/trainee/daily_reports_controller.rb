class Trainee::DailyReportsController < Trainee::BaseController
  before_action :load_draft_daily_report, only: %i(edit update destroy)
  before_action :load_submitted_daily_report, only: %i(show)
  authorize_resource

  IGNORED_PARAMS = %i(id _method authenticity_token controller action
commit).freeze
  PERMITTED_FILTER_PARAMS = %i(course_id filter_date locale status page).freeze

  helper_method :permitted_filter_params

  # GET /daily_reports
  def index
    all_reports = DailyReport.accessible_by(current_ability)
                             .recent.includes(:course)
                             .by_course_filter(params[:course_id])
                             .on_day(params[:filter_date])

    @pagy, @daily_reports = pagy(all_reports)
  end

  # GET /daily_reports/new
  def new
    @daily_report = DailyReport.new
  end

  # POST /daily_reports
  def create
    @daily_report = DailyReport.new daily_report_params
                    .merge(user_id: current_user.id)
    case params[:commit].strip
    when Settings.daily_report.status.draft.to_s
      save_as_draft
    when Settings.daily_report.status.submitted.to_s
      submit_report
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /daily_reports/:id/edit
  def edit; end

  # PATCH /trainee/daily_reports/:id
  def update
    case params[:commit]&.strip
    when Settings.daily_report.status.draft.to_s
      update_as_draft
    when Settings.daily_report.status.submitted.to_s
      update_and_submit_report
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /trainee/daily_reports/:id
  def destroy
    handle_report_destroy
    redirect_to trainee_daily_reports_path(params: request.parameters.except(
      *IGNORED_PARAMS
    ))
  end

  # GET /daily_reports/:id
  def show; end

  def permitted_filter_params
    params.permit(*PERMITTED_FILTER_PARAMS)
  end

  private

  def daily_report_params
    params.require(:daily_report)&.permit DailyReport::DAILY_REPORT_PARAMS
  end

  def save_as_draft
    handle_report_submission(
      status: Settings.daily_report.status.draft,
      success_message: t(".draft_success")
    )
  end

  def submit_report
    handle_report_submission(
      status: Settings.daily_report.status.submitted,
      success_message: t(".submit_success")
    )
  end

  def update_as_draft
    handle_update(
      status: Settings.daily_report.status.draft,
      success_message: t(".draft_success")
    )
  end

  def update_and_submit_report
    handle_update(
      status: Settings.daily_report.status.submitted,
      success_message: t(".submit_success")
    )
  end

  def handle_report_submission status:, success_message:
    @daily_report.status = status
    if @daily_report.save
      flash[:success] = success_message
      redirect_to trainee_daily_reports_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def handle_update status:, success_message:
    if @daily_report.update(daily_report_params.merge(status:))
      flash[:success] = success_message
      redirect_to trainee_daily_reports_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def handle_report_destroy
    if @daily_report.destroy
      flash[:success] = t(".destroy_success")
    else
      flash[:danger] = t(".destroy_failed")
    end
  end

  def load_draft_daily_report
    @daily_report = DailyReport.find_by(id: params[:id],
                                        status: Settings.daily_report
                                        .status.draft)

    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to trainee_daily_reports_path
  end

  def load_submitted_daily_report
    @daily_report = DailyReport.find_by(id: params[:id],
                                        status: Settings.daily_report
                                        .status.submitted)

    return if @daily_report

    flash[:danger] = t(".report_not_found")
    redirect_to trainee_daily_reports_path
  end
end
