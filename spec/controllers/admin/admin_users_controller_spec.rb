# spec/requests/admin/admin_users_spec.rb

require "rails_helper"

RSpec.describe "Admin::AdminUsers", type: :request do
  # --- Khai báo các đối tượng chính ---
  # Admin thực hiện các hành động
  let!(:current_admin) { create(:user, :admin) }
  # Các admin khác để quản lý
  let!(:other_admin) { create(:user, :admin, activated: true) }
  let!(:inactive_admin) { create(:user, :admin, activated: false) }
  # Supervisor để test chức năng thăng cấp
  let!(:supervisor) { create(:user, :supervisor) }

  # --- Helper để kiểm tra quyền truy cập của Admin ---
  shared_examples "requires admin access" do |http_method, action, params = {}|
    context "when not logged in" do
      it "redirects to the login page" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      it "redirects to the root path" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # --- Bắt đầu test các actions ---

  describe "GET /admin/admin_users" do
    it_behaves_like "requires admin access", :get, admin_admin_users_path

    context "when logged in as an admin" do
      before { sign_in(current_admin); get admin_admin_users_path }

      it "succeeds and renders the index template" do
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end

      it "assigns all admins to @admins" do
        expect(assigns(:admins)).to include(current_admin, other_admin, inactive_admin)
      end
    end
  end

  describe "GET /admin/admin_users/new" do
    it_behaves_like "requires admin access", :get, new_admin_admin_user_path

    context "when logged in as an admin" do
      it "succeeds" do
        sign_in(current_admin)
        get new_admin_admin_user_path
        expect(response).to be_successful
      end
    end
  end

  describe "POST /admin/admin_users" do
    it_behaves_like "requires admin access", :post, admin_admin_users_path

    context "when logged in as an admin" do
      let(:valid_attributes) { attributes_for(:user, role: :admin) }
      let(:invalid_attributes) { attributes_for(:user, name: "", role: :admin) }

      it "creates a new admin with valid attributes" do
        sign_in(current_admin)
        expect {
          post admin_admin_users_path, params: { user: valid_attributes }
        }.to change(User.where(role: :admin), :count).by(1)
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "fails to create an admin with invalid attributes" do
        sign_in(current_admin)
        expect {
          post admin_admin_users_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /admin/admin_users/:id/activate" do
    it_behaves_like "requires admin access", :patch, activate_admin_admin_user_path(1)

    it "activates an inactive admin" do
      sign_in(current_admin)
      patch activate_admin_admin_user_path(inactive_admin)
      expect(inactive_admin.reload.activated?).to be true
      expect(flash[:success]).to be_present
    end
  end

  describe "PATCH /admin/admin_users/:id/deactivate" do
    it_behaves_like "requires admin access", :patch, deactivate_admin_admin_user_path(1)

    it "deactivates an active admin" do
      sign_in(current_admin)
      patch deactivate_admin_admin_user_path(other_admin)
      expect(other_admin.reload.activated?).to be false
      expect(flash[:success]).to be_present
    end
  end

  describe "DELETE /admin/admin_users/:id" do
    it_behaves_like "requires admin access", :delete, admin_admin_user_path(1)

    it "deletes another admin" do
      sign_in(current_admin)
      expect {
        delete admin_admin_user_path(other_admin)
      }.to change(User, :count).by(-1)
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(admin_admin_users_path)
    end
  end

  describe "PATCH /admin/admin_users/promote" do
    it_behaves_like "requires admin access", :patch, promote_admin_admin_users_path

    context "when logged in as an admin" do
      before { sign_in(current_admin) }

      it "promotes a supervisor to admin" do
        patch promote_admin_admin_users_path, params: { supervisor_id: supervisor.id }
        expect(supervisor.reload.admin?).to be true
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(admin_admin_users_path)
      end

      it "redirects if supervisor is not found" do
        patch promote_admin_admin_users_path, params: { supervisor_id: 99999 }
        expect(supervisor.reload.supervisor?).to be true
        expect(flash[:alert]).to be_present
      end
    end
  end
end
