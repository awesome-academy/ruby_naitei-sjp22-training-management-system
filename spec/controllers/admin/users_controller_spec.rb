require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) {create(:user, :admin)}
  let(:supervisor) {create(:user, :supervisor)}
  let(:trainee) {create(:user, :trainee) }
  let(:course) {create(:course)}

  before do
    sign_in admin
  end

  describe "GET #index" do
    it "renders index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "assigns @supervisors" do
      get :index
      expect(assigns(:supervisors)).to include(supervisor)
    end

    it "filters supervisors by name" do
      supervisor2 = create(:user, :supervisor, name: "Alice")
      get :index, params: {q: {name_cont: "Alice"}}
      expect(assigns(:supervisors)).to include(supervisor2)
    end

    it "paginates supervisors" do
      create_list(:user, 20, :supervisor)
      get :index, params: {page: 2}
      expect(assigns(:pagy)).to be_present
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}

      before do
        User.supervisor.delete_all
        create_list(:user, 20, :supervisor)
        get :index, params: {page: page}
      end

      it "assigns the correct number of supervisors per page" do
        expect(assigns(:supervisors).count).to eq(per_page)
      end

      it "assigns the correct page of supervisors" do
        expected_ids = User.supervisor.limit(per_page).offset((page-1) * per_page).pluck(:id)
        actual_ids = assigns(:supervisors).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end
    end
  end

  describe "GET #show" do
    let!(:course1) {create(:course, name: "Ruby")}
    let!(:course2) {create(:course, name: "Rails")}

    before do
      supervisor.course_supervisors.create(course: course1)
      supervisor.course_supervisors.create(course: course2)
    end

    context "when the request is successful" do
      before do
        get :show, params: {id: supervisor.id}
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end

      it "assigns @supervisor_courses" do
        expect(assigns(:supervisor_courses)).to be_present
      end
    end

    it "redirects if supervisor not found" do
      get :show, params: {id: -1}
      expect(response).to redirect_to(admin_users_path)
    end

    it "filters supervisor courses by name" do
      get :show, params: {id: supervisor.id, search: "Ruby"}
      expect(assigns(:supervisor_courses).map(&:name)).to include("Ruby")
    end

    it "filters supervisor courses by course_id" do
      get :show, params: {id: supervisor.id, course_id: course2.id}
      expect(assigns(:supervisor_courses).map(&:id)).to all(satisfy {|id| Course.find(id).id == course2.id})
    end

    it "paginates supervisor courses" do
      create_list(:course, 15).each {|c| supervisor.course_supervisors.create(course: c)}
      get :show, params: {id: supervisor.id, page: 2}
      expect(assigns(:pagy)).to be_present
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}
      let!(:courses) {create_list(:course, 20)}

      before do
        supervisor.course_supervisors.delete_all
        courses.each {|c| supervisor.course_supervisors.create(course: c)}
        get :show, params: {id: supervisor.id, page: page}
      end

      it "assigns the correct number of supervisor courses per page" do
        expect(assigns(:supervisor_courses).count).to eq(per_page)
      end

      it "assigns the correct page of supervisor courses" do
        expected_ids = courses.sort_by(&:created_at).reverse
                              .map(&:id)
                              .slice((page - 1) * per_page, per_page)
        actual_ids = assigns(:supervisor_courses).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end
    end
  end

  describe "PATCH #update_status" do
    context "when the update is successful" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(true)
        patch :update_status, params: {id: supervisor.id, confirmed: Time.zone.now}
      end

      it "sets a flash success message" do
        expect(flash[:success]).to eq(I18n.t("admin.users.update_status.update_success"))
      end
    end

    context "when the update fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :update_status, params: {id: supervisor.id, confirmed: Time.zone.now}
      end

      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("admin.users.update_status.update_failed"))
      end
    end
  end

  describe "PATCH #update" do
    it "updates supervisor and redirects" do
      patch :update, params: {id: supervisor.id, user: {name: "New Name"}}
      expect(flash[:success]).to eq(I18n.t("admin.users.update.update_success"))
    end

    it "does not update supervisor and renders :show on failure" do
      allow_any_instance_of(User).to receive(:update).and_return(false)
      patch :update, params: {id: supervisor.id, user: {name: "" }}
      expect(flash[:danger]).to eq(I18n.t("admin.users.update.update_failed"))
    end

    it "renders :show on update failure" do
      allow_any_instance_of(User).to receive(:update).and_return(false)
      patch :update, params: {id: supervisor.id, user: {name: "" }}
      expect(response).to render_template(:show)
    end
  end

  describe "DELETE #delete_user_course" do
    let!(:user_course) {create(:course_supervisor, user: supervisor, course: course)}
    let!(:user_course2) {create(:course_supervisor, course: course)}

    context "on successful deletion" do
      before do
        delete :delete_user_course, params: {id: supervisor.id, course_id: course.id}
      end

      it "deletes the user course" do
        expect(CourseSupervisor.exists?(user_course.id)).to be_falsey
      end

      it "redirects with a success message" do
        expect(flash[:success]).to eq(I18n.t("admin.users.delete_user_course.delete_success"))
      end

      it "assigns the @user_course instance variable" do
        expect(assigns(:user_course)).to eq(user_course)
      end
    end

    context "when the user course is not found" do
      before do
        delete :delete_user_course, params: {id: supervisor.id, course_id: -1}
      end

      it "redirects" do
        expect(response).to redirect_to(admin_user_path(supervisor))
      end

      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("admin.users.delete_user_course.course.not_found"))
      end
    end

    context "when the user course is successfully destroyed" do
      before do
        allow_any_instance_of(CourseSupervisor).to receive(:destroy).and_return(true)
        delete :delete_user_course, params: {id: supervisor.id, course_id: course.id}
      end

      it "destroys the user course" do
        expect(flash[:success]).to eq(I18n.t("admin.users.delete_user_course.delete_success"))
      end
    end

    context "when the user course deletion fails" do
      before do
        allow_any_instance_of(CourseSupervisor).to receive(:destroy).and_return(false)
        delete :delete_user_course, params: {id: supervisor.id, course_id: course.id}
      end

      it "does not destroy the user course" do
        expect(CourseSupervisor.exists?(user_course.id)).to be_truthy
      end

      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("admin.users.delete_user_course.delete_failed"))
      end
    end
  end

  describe "PATCH #bulk_deactivate" do
    it "toggles supervisor statuses and redirects" do
      patch :bulk_deactivate, params: {supervisor_ids: [supervisor.id]}
      expect(flash[:success]).to eq(I18n.t("admin.users.bulk_deactivate.bulk_statuses_success", count: 1))
    end

    it "sets flash success when some statuses are updated" do
      allow(controller).to receive(:bulk_deactivate_users).and_return(2)
      patch :bulk_deactivate, params: {supervisor_ids: [supervisor.id]}
      expect(flash[:success]).to eq(I18n.t("admin.users.bulk_deactivate.bulk_statuses_success", count: 1))
    end

    it "sets flash danger when no supervisors are selected" do
      patch :bulk_deactivate, params: {supervisor_ids: []}
      expect(flash[:danger]).to eq(I18n.t("admin.users.bulk_deactivate.supervisor_no_selection"))
    end

    it "sets flash danger when no statuses are updated" do
      allow(controller).to receive(:toggle_supervisors_status).and_return(0)
      patch :bulk_deactivate, params: {supervisor_ids: [supervisor.id]}
      expect(flash[:danger]).to eq(I18n.t("admin.users.bulk_deactivate.bulk_statuses_failed"))
    end
  end

  describe "PATCH #add_role_supervisor" do
    context "when successful" do
      before do
        patch :add_role_supervisor, params: {supervisor_ids: [trainee.id]}
      end

      it "updates the trainee's role to supervisor" do
        expect(trainee.reload.role).to eq("supervisor")
      end

      it "sets a flash success message" do
        expect(flash[:success]).to eq(I18n.t("admin.users.add_role_supervisor.add_success"))
      end
    end

    context "when adding a role fails" do
      before do
        allow_any_instance_of(ActiveRecord::Relation).to receive(:update_all).and_raise(StandardError)
        patch :add_role_supervisor, params: {supervisor_ids: [trainee.id]}
      end

      it "sets a flash danger message" do
        expect(flash[:danger]).to eq(I18n.t("admin.users.add_role_supervisor.add_failed"))
      end

      it "does not update the trainee's role" do
        expect(trainee.reload.role).not_to eq("supervisor")
      end
    end

    context "when no supervisor is selected" do
      before do
        patch :add_role_supervisor, params: {supervisor_ids: []}
      end

      it "redirects to the new supervisor path" do
        expect(response).to redirect_to(new_supervisor_admin_users_path)
      end
    end
  end
end
