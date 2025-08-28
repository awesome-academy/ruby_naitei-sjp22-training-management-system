# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supervisor::DailyReportsController, type: :controller do
  let(:supervisor) {create(:user, :supervisor)}
  let(:user) {create(:user, :trainee)}
  let(:course) {create(:course)}
  let!(:user_course) {create(:user_course, user: user, course: course)}
  let!(:course_supervisor) {create(:course_supervisor, user: supervisor, course: course)}

  before {sign_in supervisor}

  describe "GET #index" do
    let!(:daily_report) do
      travel_to(3.days.ago) {create(:daily_report, :submitted, user: user, course: course)}
    end
    let!(:daily_report_unsubmitted) do
      travel_to(2.days.ago) {create(:daily_report, user: user, course: course)}
    end

    before {get :index}

    it "returns a successful response" do
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "assigns @daily_reports including submitted and draft reports" do
      expect(assigns(:daily_reports)).to include(daily_report, daily_report_unsubmitted)
    end

    it "assigns a pagy object" do
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    context "with filtering" do
      let(:user_with_reports) {create(:user, name: "Alice")}
      let(:course_for_alice) {create(:course)}
      let!(:user_course_for_alice) {create(:user_course, user: user_with_reports, course: course_for_alice)}
      let!(:course_supervisor_for_alice) {create(:course_supervisor, user: supervisor, course: course_for_alice)}
      let!(:report_from_alice) do
        travel_to(4.days.ago) {create(:daily_report, :submitted, user: user_with_reports, course: course_for_alice)}
      end

      before do
        get :index, params: {q: {user_name_cont: "Alice"}}
      end

      it "does not include reports from other users" do
        expect(assigns(:daily_reports)).not_to include(daily_report)
      end
    end

    context "with pagination" do
      let(:per_page) {Settings.ui.items_per_page}

      before do
        (per_page * 2).times do |i|
          current_user = create(:user)
          current_course = create(:course)
          create(:user_course, user: current_user, course: current_course)
          create(:course_supervisor, user: supervisor, course: current_course)
          travel_to((10 + i).days.ago) do
            create(:daily_report, :submitted, user: current_user, course: current_course)
          end
        end
        get :index, params: {page: 2}
      end

      it "paginates reports" do
        expect(assigns(:daily_reports).size).to eq(2)
      end
    end
  end

  describe "GET #show" do
    let!(:daily_report) do
      travel_to(1.day.ago) {create(:daily_report, :submitted, user: user, course: course)}
    end
    let!(:daily_report_unsubmitted) do
      travel_to(2.days.ago) {create(:daily_report, user: user, course: course)}
    end

    context "when daily report is found" do
      before {get :show, params: {id: daily_report.id}}

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
  end
end
