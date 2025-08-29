require "rails_helper"

RSpec.describe Supervisor::UsersController, type: :controller do
  let(:supervisor) { create(:user, :supervisor) }
  let(:trainee) { create(:user, :trainee) }
  let(:course) { create(:course) }
  let!(:user_course) { create(:user_course, user: trainee, course: course) }

  before do
    sign_in supervisor
  end

  describe "GET #index" do
    before { get :index }

    it "renders index template" do
      expect(response).to render_template(:index)
    end

    it "assigns @trainees" do
      expect(assigns(:trainees)).to include(trainee)
    end

    it "filters trainees by name" do
      trainee2 = create(:user, :trainee, name: "Alice")
      get :index, params: { q: { name_cont: "Alice" } }
      expect(assigns(:trainees)).to include(trainee2)
    end

    it "paginates trainees" do
      create_list(:user, 20, :trainee)
      get :index, params: { page: 2 }
      expect(assigns(:pagy)).to be_present
    end
  end

  describe "GET #show" do
    let!(:course1) { create(:course, name: "Ruby") }
    let!(:course2) { create(:course, name: "Rails") }

    before do
      create(:user_course, user: trainee, course: course1)
      create(:user_course, user: trainee, course: course2)
    end

    it "renders show template" do
      get :show, params: { id: trainee.id }
      expect(response).to render_template(:show)
    end

    it "assigns @trainee_courses" do
      get :show, params: { id: trainee.id }
      expect(assigns(:trainee_courses)).to be_present
    end

    it "redirects if trainee not found" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(supervisor_users_path)
      expect(flash[:danger]).to eq(I18n.t("supervisor.users.trainee_not_found"))
    end

    it "filters trainee courses by name" do
      get :show, params: { id: trainee.id, q: { name_cont: "Ruby" } }
      expect(assigns(:trainee_courses).map(&:name)).to include("Ruby")
    end

    it "paginates trainee courses" do
      create_list(:course, 15).each { |c| create(:user_course, user: trainee, course: c) }
      get :show, params: { id: trainee.id, page: 2 }
      expect(assigns(:pagy)).to be_present
    end
  end

describe "PATCH #update_status" do
  context "when update succeeds" do
    before do
      patch :update_status, params: { id: trainee.id, activated: "true" }
    end

    it "sets success flash" do
      expect(flash[:success]).to eq(I18n.t("supervisor.users.update_status.update_success"))
    end

    it "redirects to users path" do
      expect(response).to redirect_to(supervisor_users_path)
    end
  end

    context "when update fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update_status, params: { id: trainee.id, confirmed_at: nil }
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update_status.update_failed"))
      end

      it "redirects to users path" do
        expect(response).to redirect_to(supervisor_users_path)
      end
    end
  end

  describe "PATCH #update_user_course_status" do
    context "on success" do
      it "updates course status and sets flash" do
        patch :update_user_course_status, params: { id: trainee.id, course_id: course.id, status: "finished" }
        expect(flash[:success]).to eq(I18n.t("supervisor.users.update_user_course_status.update_success"))
      end
    end

    context "on failure" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update).and_return(false)
        patch :update_user_course_status, params: { id: trainee.id, course_id: course.id, status: "finished" }
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update_user_course_status.update_failed"))
      end
    end

    context "when user course not found" do
      it "redirects with danger flash" do
        patch :update_user_course_status, params: { id: trainee.id, course_id: -1, status: "finished" }
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.course_not_found"))
        expect(response).to redirect_to(supervisor_user_path(trainee))
      end
    end
  end

  describe "DELETE #delete_user_course" do
    context "success" do
      it "deletes course and sets flash" do
        delete :delete_user_course, params: { id: trainee.id, course_id: course.id }
        expect(flash[:success]).to eq(I18n.t("supervisor.users.delete_user_course.delete_success"))
      end
    end

    context "when user course not found" do
      it "redirects with danger flash" do
        delete :delete_user_course, params: { id: trainee.id, course_id: -1 }
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.course_not_found"))
        expect(response).to redirect_to(supervisor_user_path(trainee))
      end
    end
  end

  describe "PATCH #bulk_deactivate" do
    context "when no trainee IDs are selected" do
      # This before block simulates the HTTP request
      before { patch :bulk_deactivate, params: { trainee_ids: nil } }

      it "sets a danger flash message" do
        # Note: The I18n key is namespaced under the method that calls `t`
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.bulk_deactivate.trainee_no_selection"))
      end

      it "redirects to the users index page" do
        expect(response).to redirect_to(supervisor_users_path)
      end
    end

    context "when trainee IDs are provided" do
      let!(:trainee_to_deactivate) { create(:user, :trainee, confirmed_at: Time.current) }
      let!(:trainee_to_activate) { create(:user, :trainee, confirmed_at: nil) }

      before do
        patch :bulk_deactivate, params: { trainee_ids: [trainee_to_deactivate.id, trainee_to_activate.id] }
      end

      it "toggles the status of the selected trainees" do
        expect(trainee_to_deactivate.reload.confirmed_at).to be_nil
        expect(trainee_to_activate.reload.confirmed_at).to be_present
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("supervisor.users.bulk_statuses_success", count: 2))
      end

      it "redirects to the users index page" do
        expect(response).to redirect_to(supervisor_users_path)
      end
    end
  end

  describe "private methods" do
    let(:supervisor) { create(:user, :supervisor) }
    before do
      sign_in supervisor
      allow_any_instance_of(User).to receive(:send_devise_notification)
    end

    describe "#toggle_trainees_status" do
      it "toggles trainees confirmed_at and returns updated count" do
        trainee1 = create(:user, :trainee, confirmed_at: nil)
        trainee2 = create(:user, :trainee, confirmed_at: Time.current)

        result = controller.send(:toggle_trainees_status, [trainee1, trainee2])

        expect(result).to eq(2)
        expect(trainee1.reload.confirmed_at).to be_present
        expect(trainee2.reload.confirmed_at).to be_nil
      end
    end
  end

  describe "PATCH #update" do
    context "when update succeeds" do
      it "updates trainee and redirects" do
        patch :update, params: { id: trainee.id, user: { name: "New Name" } }
        expect(flash[:success]).to eq(I18n.t("supervisor.users.update.update_success"))
        expect(response).to redirect_to(supervisor_user_path(trainee))
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update, params: { id: trainee.id, user: { name: "" } }
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update.update_failed"))
      end

      it "renders :show" do
        expect(response).to render_template(:show)
      end
    end
  end
end
