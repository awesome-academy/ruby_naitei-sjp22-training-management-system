require 'rails_helper'

RSpec.describe Admin::DailyReportsController, type: :controller do
  let(:admin) {create(:user, :admin)}

  before do
    sign_in admin
  end

  describe "GET #index" do
    let(:user) {create(:user)}
    let(:course) {create(:course)}
    let!(:user_course) {create(:user_course, user: user, course: course)}

    let!(:daily_report) do
      travel_to(3.days.ago) {create(:daily_report, :submitted, user: user, course: course)}
    end
    let!(:daily_report_unsubmitted) do
      travel_to(2.days.ago) {create(:daily_report, user: user, course: course)}
    end

    before do
      get :index
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "assigns @daily_reports with submitted reports" do
      expect(assigns(:daily_reports)).to include(daily_report)
    end

    it "assigns a pagy object" do
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    context "with filtering" do
      let(:user_with_reports) {create(:user, name: "Alice")}
      let(:course_for_alice) {create(:course)}
      let!(:user_course_for_alice) {create(:user_course, user: user_with_reports, course: course_for_alice)}
      let!(:report_from_alice) do
        travel_to(4.days.ago) {create(:daily_report, :submitted, user: user_with_reports, course: course_for_alice)}
      end

      before do
        get :index, params: {q: {user_name_cont: "Alice"}}
      end

      it "filters reports by user name" do
        expect(assigns(:daily_reports)).to include(report_from_alice)
      end

      it "does not include reports from other users" do
        expect(assigns(:daily_reports)).not_to include(daily_report)
      end
    end

    context "with pagination" do
      let(:per_page) { Settings.ui.items_per_page }
      before do
        (per_page * 2).times do |i|
          current_user = create(:user)
          current_course = create(:course)
          create(:user_course, user: current_user, course: current_course)

          travel_to((10 + i).days.ago) do
            create(:daily_report, :submitted, user: current_user, course: current_course)
          end
        end
        get :index, params: {page: 2}
      end

      it "paginates reports" do
        expect(assigns(:daily_reports).size).to eq(per_page)
      end
    end
  end

  describe "GET #show" do
    let(:user) {create(:user)}
    let(:course) {create(:course)}
    let!(:user_course) {create(:user_course, user: user, course: course)}

    let!(:daily_report) do
      travel_to(1.day.ago) {create(:daily_report, :submitted, user: user, course: course)}
    end
    let!(:daily_report_unsubmitted) do
      travel_to(2.days.ago) {create(:daily_report, user: user, course: course)}
    end

    context "when daily report is found" do
      before do
        get :show, params: {id: daily_report.id}
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end

      it "assigns @daily_report" do
        expect(assigns(:daily_report)).to eq(daily_report)
      end
    end

    context "when daily report is not found" do
      before do
        get :show, params: {id: -1}
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(admin_daily_reports_path)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.daily_reports.report_not_found"))
      end
    end

    context "when daily report is not submitted" do
      before do
        get :show, params: {id: daily_report_unsubmitted.id}
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(admin_daily_reports_path)
      end
    end
  end
end
