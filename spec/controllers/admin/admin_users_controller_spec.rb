require 'rails_helper'

RSpec.describe Admin::AdminUsersController, type: :controller do
  let!(:admin_user) {create(:user, :admin)}
  let!(:other_admin) {create(:user, :admin)}
  let!(:supervisor_user) {create(:user, :supervisor)}

  before do
    sign_in admin_user
  end

  describe "GET #index" do
    before { get :index }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "assigns @admins" do
      expect(assigns(:admins)).to include(admin_user, other_admin)
    end

    it "assigns a pagy object" do
      expect(assigns(:pagy)).to be_a(Pagy)
    end
  end

  describe "GET #show" do
    let!(:course) {create(:course, :finished)}
    let!(:course_supervisor) {create(:course_supervisor, course: course, user: other_admin)}
    let(:other_admin) {create(:user, :admin)}

    context "when the request is successful" do
      before {get :show, params: {id: other_admin.id }}

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "assigns @admin" do
        expect(assigns(:admin)).to eq(other_admin)
      end

      it "assigns @courses" do
        expect(assigns(:courses)).to include(course)
      end

      it "assigns a pagy object for courses" do
        expect(assigns(:pagy)).to be_a(Pagy)
      end
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}
      let!(:courses) {create_list(:course, 20)}
      let!(:supervisor) {create(:user, :admin)}

      before do
        supervisor.course_supervisors.delete_all
        courses.each {|c| supervisor.course_supervisors.create(course: c)}
        get :show, params: {id: supervisor.id, page: page}
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "assigns @admin" do
        expect(assigns(:admin)).to eq(supervisor)
      end

      it "assigns the correct number of supervisor courses per page" do
        expect(assigns(:courses).size).to eq(per_page)
      end

      it "assigns the correct page of supervisor courses" do
        expected_ids = courses.sort_by(&:created_at).reverse
                            .map(&:id)
                            .slice((page - 1) * per_page, per_page)
        actual_ids = assigns(:courses).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end

      it "assigns a pagy object for courses" do
        expect(assigns(:pagy)).to be_a(Pagy)
      end

      it "pagy object has correct total count" do
        expect(assigns(:pagy).count).to eq(courses.count)
      end
    end

    context "when admin is not found" do
      before {get :show, params: {id: -1}}

      it "redirects to the admin users path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

     
    end
  end


  describe "GET #new" do
    before { get :new }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "assigns a new supervisor" do
      expect(assigns(:supervisor)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    let(:valid_params) {{user: attributes_for(:user)}}
    let(:invalid_params) {{user: {email: "" }}}

    context "with valid params" do
      before {post :create, params: valid_params}

      it "creates a new admin" do
        expect(User.last.role).to eq("admin")
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("admin.admin_users.create.admin_created_successfully"))
      end
    end

    context "with invalid params" do
      before {post :create, params: invalid_params}

      it "renders new template with unprocessable_entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("admin.admin_users.create.creation_failed"))
      end
    end
  end

  describe "PATCH #activate" do
    context "when activation succeeds" do
      before do
        allow_any_instance_of(User).to receive(:confirmed_at?).and_return(true)
        patch :activate, params: {id: other_admin.id}
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("admin.admin_users.activate.admin_activated"))
      end
    end

    context "when activation fails" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch :activate, params: { id: other_admin.id }
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("admin.admin_users.activate.activation_failed"))
      end
    end
  end

  describe "PATCH #deactivate" do
  context "when deactivation succeeds" do
      before do
        allow_any_instance_of(User).to receive(:update).with(confirmed_at: nil).and_return(true)
        patch :deactivate, params: {id: other_admin.id}
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("admin.admin_users.deactivate.admin_deactivated"))
      end
    end

    context "when deactivation fails" do
      before do
        allow_any_instance_of(User).to receive(:update).with(confirmed_at: nil).and_return(false)
        patch :deactivate, params: {id: other_admin.id}
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("admin.admin_users.deactivate.deactivation_failed"))
      end
    end
  end

  describe "DELETE #destroy" do
    context "when destroy succeeds" do
      before do
        allow_any_instance_of(User).to receive(:destroy).and_return(true)
        delete :destroy, params: {id: other_admin.id}
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("admin.admin_users.destroy.admin_deleted"))
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
        delete :destroy, params: {id: other_admin.id}
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("admin.admin_users.destroy.deletion_failed"))
      end
    end
  end

  describe "PATCH #promote" do
    context "with valid supervisor" do
      before {patch :promote, params: {supervisor_id: supervisor_user.id}}

      it "promotes supervisor to admin" do
        expect(supervisor_user.reload.role).to eq("admin")
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets success flash" do
        expect([flash[:success], flash[:danger]].compact.first).to eq(I18n.t("admin.admin_users.promote.promote_success"))
      end
    end

    context "with invalid supervisor_id" do
      before {patch :promote, params: {supervisor_id: -1}}

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end


    end

    context "when promote fails" do
      before do
        # giả lập update fail
        allow_any_instance_of(User).to receive(:update).with(role: :admin).and_return(false)
        patch :promote, params: {supervisor_id: supervisor_user.id}
      end

      it "redirects to admin_admin_users_path" do
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("admin.admin_users.promote.promote_failed"))
      end
    end
  end
end
