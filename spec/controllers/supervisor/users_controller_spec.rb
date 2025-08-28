require "rails_helper"

RSpec.describe Supervisor::UsersController, type: :controller do
  let(:supervisor) {create(:user, :supervisor)}
  let(:trainee) {create(:user, :trainee)}
  let(:course) {create(:course)}
  let!(:user_course) {create(:user_course, user: trainee, course: course)}

  before do
    sign_in supervisor
  end

  describe "GET #index" do
    context "index" do
      before do
        get :index
      end

      it "renders index template" do
        expect(response).to render_template(:index)
      end

      it "assigns @trainees" do
        expect(assigns(:trainees)).to include(trainee)
      end
    end


    it "filters trainees by name" do
      trainee2 = create(:user, :trainee, name: "Alice")
      get :index, params: {q: {name_cont: "Alice"}}
      expect(assigns(:trainees)).to include(trainee2)
    end

    it "paginates trainees" do
      create_list(:user, 20, :trainee)
      get :index, params: {page: 2}
      expect(assigns(:pagy)).to be_present
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}
      let!(:trainees) {create_list(:user, 20, :trainee)}

      before do
        get :index, params: {page: page}
      end

      it "assigns the correct number of trainees per page" do
        expect(assigns(:trainees).count).to eq(per_page)
      end
    end
  end

  describe "GET #show" do
    let!(:course1) {create(:course, name: "Ruby")}
    let!(:course2) {create(:course, name: "Rails")}

    before do
      create(:user_course, user: trainee, course: course1)
      create(:user_course, user: trainee, course: course2)
    end

    context "when the request is successful" do
      before do
        get :show, params: {id: trainee.id}
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end

      it "assigns @trainee_courses" do
        expect(assigns(:trainee_courses)).to be_present
      end
    end

    it "redirects if trainee not found" do
      get :show, params: {id: -1}
      expect(response).to redirect_to(supervisor_users_path)
    end

    it "filters trainee courses by name" do
      get :show, params: {id: trainee.id, search: "Ruby"}
      expect(assigns(:trainee_courses).map(&:name)).to include("Ruby")
    end

    it "filters trainee courses by course_id" do
      get :show, params: {id: trainee.id, course: course2.id}
      expect(assigns(:trainee_courses).map(&:id)).to all(eq(course2.id))
    end

    it "paginates trainee courses" do
      create_list(:course, 15).each {|c| create(:user_course, user: trainee, course: c)}
      get :show, params: {id: trainee.id, page: 2}
      expect(assigns(:pagy)).to be_present
    end
  end

  describe "PATCH #update_status" do
    context "when the update is successful" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(true)
        patch :update_status, params: {id: trainee.id, confirmed: Time.zone.now}
      end

      it "sets a flash success message" do
        expect(flash[:success]).to eq(I18n.t("supervisor.users.update_status.update_success"))
      end
    end

    context "when the update fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update_status, params: {id: trainee.id, confirmed: Time.zone.now}
      end

      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update_status.update_failed"))
      end
    end
  end

  describe "PATCH #bulk_deactivate" do
    it "toggles trainee statuses and redirects" do
      patch :bulk_deactivate, params: {trainee_ids: [trainee.id]}
      expect(flash[:success]).to eq(I18n.t("supervisor.users.bulk_statuses_success", count: 1))
    end

    it "sets flash danger when no trainees are selected" do
      patch :bulk_deactivate, params: {trainee_ids: []}
      expect(flash[:danger]).to eq(I18n.t("supervisor.users.bulk_deactivate.trainee_no_selection"))
    end

    it "sets flash danger when no statuses are updated" do
      allow(controller).to receive(:toggle_trainees_status).and_return(0)
      patch :bulk_deactivate, params: {trainee_ids: [trainee.id]}
      expect(flash[:danger]).to eq(I18n.t("supervisor.users.bulk_statuses_failed"))
    end
  end

  describe "PATCH #update_user_course_status" do
    context "on success" do
      it "updates the user course status" do
        patch :update_user_course_status, params: {id: trainee.id, course_id: course.id, status: "finished"}
        expect(flash[:success]).to eq(I18n.t("supervisor.users.update_user_course_status.update_success"))
      end
    end

    context "on failure" do
      before do
        allow_any_instance_of(UserCourse).to receive(:update).and_return(false)
        patch :update_user_course_status, params: {id: trainee.id, course_id: course.id, status: "finished"}
      end

      it "sets a danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update_user_course_status.update_failed"))
      end
    end
  end

  describe "DELETE #delete_user_course" do
    context "on successful deletion" do
      it "deletes the user course" do
        delete :delete_user_course, params: {id: trainee.id, course_id: course.id}
        expect(flash[:success]).to eq(I18n.t("supervisor.users.delete_user_course.delete_success"))
      end
    end

    context "when user course not found" do
      it "redirects with danger" do
        delete :delete_user_course, params: {id: trainee.id, course_id: -1}
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.delete_user_course.course.not_found"))
      end
    end

    context "when deletion fails" do
      before do
        allow_any_instance_of(UserCourse).to receive(:destroy).and_return(false)
        delete :delete_user_course, params: {id: trainee.id, course_id: course.id}
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.delete_user_course.delete_failed"))
      end
    end
  end

  describe "PATCH #update" do
    it "updates trainee and redirects" do
      patch :update, params: {id: trainee.id, user: {name: "New Name"}}
      expect(flash[:success]).to eq(I18n.t("supervisor.users.update.update_success"))
    end

    context "when update fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update, params: {id: trainee.id, user: {name: ""}}
      end

      it "sets danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.users.update.update_failed"))
      end

      it "renders :show template" do
        expect(response).to render_template(:show)
      end
    end
  end
end
