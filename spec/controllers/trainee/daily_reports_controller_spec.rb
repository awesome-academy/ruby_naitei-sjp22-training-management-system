require "rails_helper"

RSpec.describe Trainee::DailyReportsController, type: :controller do
  let(:trainee) {create(:user, :trainee)}
  let(:course) {create(:course)}
  let!(:user_course) {create(:user_course, course: course, user: trainee)}

  before {sign_in trainee}

  describe "GET #index" do
    let!(:draft_report) do
      create(:daily_report, :draft, user: trainee,
             course: course)
    end
    let!(:submitted_report) do
      travel_to 1.day.ago do
        create(:daily_report, :submitted, user: trainee, course: course)
      end
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "assigns all daily reports of the current trainee" do
      get :index
      expect(assigns(:daily_reports)).to match_array([draft_report,
             submitted_report])
    end

    it "does not assign daily reports from other users" do
      other_user = create(:user)
      other_course = create(:course)
      create(:user_course, user: other_user, course: other_course)
      create(:daily_report, user: other_user, course: other_course)

      get :index
      expect(assigns(:daily_reports)).not_to include(DailyReport.last)
    end

    context "with valid pagination params" do
      let(:page) {2}
      let(:per_page) {Settings.ui.items_per_page}

      before do
        (per_page * 2).times do |i|
          create(:daily_report, :submitted, user: trainee,
                 created_at: (i + 1).days.ago, course: course)
        end

        get :index, params: {page: page}
      end

      it "assigns the correct number of daily reports per page" do
        expect(assigns(:daily_reports).size).to eq(per_page)
      end

      it "paginates daily reports" do
        expect(assigns(:pagy)).to be_present
      end
    end
  end

  describe "GET #show" do
    let!(:daily_report) do
      create(:daily_report, :submitted, user: trainee,
             course: course)
    end
    let(:other_user) {create(:user)}
    let!(:other_user_course) do
      create(:user_course, user: other_user,
             course: course)
    end
    let!(:other_report) do
      create(:daily_report, :submitted, user: other_user,
             course: course)
    end

    context "when the report belongs to the current trainee" do
      before do
        get :show, params: {id: daily_report.id}
      end

      it "assigns the requested daily report" do
        expect(assigns(:daily_report)).to eq(daily_report)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when the report does not belong to the current trainee" do
      before do
        get :show, params: {id: other_report.id}
      end

      it "sets a danger flash message for not authorized" do
        expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.report_not_found"))
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(root_path, locale: I18n.locale)
      end
    end

    context "when the report is not found" do
      before do
        get :show, params: {id: -1}
      end

      it "sets a danger flash message for report not found" do
        expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.report_not_found"))
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(trainee_daily_reports_path)
      end
    end
  end

  describe "GET #new" do
    before {get :new}

    it "renders the new template" do
      expect(response).to render_template(:new)
    end

    it "assigns a new daily_report" do
      expect(assigns(:daily_report)).to be_a_new(DailyReport)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        daily_report: {
          content: "Today I studied RSpec",
          course_id: course.id
        }
      }
    end

    let(:invalid_params) do
      {
        daily_report: {
          content: "",
          course_id: course.id
        }
      }
    end

    context "with valid params" do
      context "as a draft" do
        before do
          post :create,
               params: valid_params.merge(commit: Settings.daily_report.status.draft.to_s)
        end

        it "creates a new draft daily_report" do
          expect(DailyReport.last.draft?).to be true
        end

        it "assigns the correct user to the new draft report" do
          expect(DailyReport.last.user).to eq(trainee)
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("trainee.daily_reports.draft_success"))
        end

        it "redirects to the index page" do
          expect(response).to redirect_to(trainee_daily_reports_path)
        end
      end

      context "as a submitted report" do
        before do
          post :create,
               params: valid_params.merge(commit: Settings.daily_report.status.submitted.to_s)
        end

        it "creates and submits a new daily_report" do
          expect(DailyReport.last.submitted?).to be true
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("trainee.daily_reports.submit_success"))
        end

        it "redirects to the index page" do
          expect(response).to redirect_to(trainee_daily_reports_path)
        end
      end
    end

    context "with invalid params" do
      before do
        post :create,
             params: invalid_params.merge(commit: Settings.daily_report.status.draft.to_s)
      end

      it "does not create a daily report" do
        expect do
          post :create,
               params: invalid_params.merge(commit: Settings.daily_report.status.draft.to_s)
        end.not_to change(DailyReport, :count)
      end

      it "assigns a new daily report" do
        expect(assigns(:daily_report)).to be_a_new(DailyReport)
      end

      it "assigns the daily report with content errors" do
        expect(assigns(:daily_report).errors[:content]).to be_present
      end

      it "re-renders the new template" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    let!(:draft_report) do
      create(:daily_report, :draft, user: trainee, course: course)
    end
    let!(:submitted_report) do
      travel_to 1.day.ago do
        create(:daily_report, :submitted, user: trainee, course: course)
      end
    end

    context "when the report is a draft" do
      before do
        get :edit, params: {id: draft_report.id}
      end

      it "assigns the requested draft daily report" do
        expect(assigns(:daily_report)).to eq(draft_report)
      end

      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "when the report is already submitted" do
      before do
        get :edit, params: {id: submitted_report.id}
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(trainee_daily_reports_path)
      end

      it "sets a danger flash message for report not found" do
        expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.report_not_found"))
      end
    end
  end

  describe "PATCH #update" do
    let!(:daily_report) do
      create(:daily_report, :draft, user: trainee, course: course,
             content: "Old content")
    end
    let(:new_content_draft) {"Updated content"}
    let(:new_content_submitted) {"Updated and submitted"}

    context "with valid params" do
      context "and updating to a draft" do
        before do
          patch :update, params: {
            id: daily_report.id,
            daily_report: {content: new_content_draft},
            commit: Settings.daily_report.status.draft.to_s
          }
        end

        it "updates the content of the daily_report" do
          expect(daily_report.reload.content).to eq(new_content_draft)
        end

        it "updates the daily_report to a draft" do
          expect(daily_report.reload.draft?).to be true
        end

        it "sets a success flash message for a draft update" do
          expect(flash[:success]).to eq(I18n.t("trainee.daily_reports.draft_success"))
        end

        it "redirects to the index page" do
          expect(response).to redirect_to(trainee_daily_reports_path)
        end
      end

      context "and updating to a submitted report" do
        before do
          patch :update, params: {
            id: daily_report.id,
            daily_report: {content: new_content_submitted},
            commit: Settings.daily_report.status.submitted.to_s
          }
        end

        it "updates the daily_report to submitted" do
          expect(daily_report.reload.content).to eq(new_content_submitted)
        end

        it "sets the daily_report status to submitted" do
          expect(daily_report.reload.submitted?).to be true
        end

        it "sets a success flash message for a submission update" do
          expect(flash[:success]).to eq(I18n.t("trainee.daily_reports.submit_success"))
        end

        it "redirects to the index page" do
          expect(response).to redirect_to(trainee_daily_reports_path)
        end
      end
    end

    context "with invalid params" do
      before do
        patch :update, params: {
          id: daily_report.id,
          daily_report: {content: ""},
          commit: Settings.daily_report.status.draft.to_s
        }
      end

      it "does not update the daily_report" do
        expect(daily_report.reload.content).to eq("Old content")
      end

      it "assigns the daily_report with errors" do
        expect(assigns(:daily_report).errors[:content]).to be_present
      end

      it "re-renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:draft_report) do
      create(:daily_report, :draft, user: trainee,
             course: course)
    end
    let!(:submitted_report) do
      travel_to 1.day.ago do
        create(:daily_report, :submitted, user: trainee, course: course)
      end
    end
    let!(:other_user_report) do
      other_user = create(:user)
      other_course = create(:course)
      create(:user_course, user: other_user, course: other_course)
      create(:daily_report, user: other_user, course: other_course)
    end

    context "when the report is a draft" do
      it "destroys the draft daily report" do
        expect do
          delete :destroy,
                 params: {id: draft_report.id}
        end.to change(DailyReport, :count).by(-1)
      end

      it "sets a success flash message" do
        delete :destroy, params: {id: draft_report.id}
        expect(flash[:success]).to eq(I18n.t("trainee.daily_reports.destroy.destroy_success"))
      end

      it "redirects to the index page" do
        delete :destroy, params: {id: draft_report.id}
        expect(response).to redirect_to(trainee_daily_reports_path)
      end
    end

    context "when the report is already submitted" do
      before do
        delete :destroy, params: {id: submitted_report.id}
      end

      it "does not destroy the submitted daily report" do
        expect do
          delete :destroy,
                 params: {id: submitted_report.id}
        end.not_to change(DailyReport, :count)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.report_not_found"))
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(trainee_daily_reports_path)
      end
    end

    context "when the report does not belong to the current trainee" do
      before do
        delete :destroy, params: {id: other_user_report.id}
      end

      it "does not destroy the report" do
        expect do
          delete :destroy,
                 params: {id: other_user_report.id}
        end.not_to change(DailyReport, :count)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.report_not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end

    it "sets a danger flash message when the report fails to be destroyed" do
      mock_report = double(DailyReport, destroy: false)
      controller.instance_variable_set(:@daily_report, mock_report)
      controller.send(:handle_report_destroy)
      expect(flash[:danger]).to eq(I18n.t("trainee.daily_reports.destroy.destroy_failed"))
    end
  end
end
