# spec/requests/admin/users_spec.rb

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  # --- Khai báo các đối tượng chính ---
  let!(:admin) { create(:user, :admin) }
  let!(:supervisor1) { create(:user, :supervisor, name: "Supervisor One", activated: true) }
  let!(:supervisor2) { create(:user, :supervisor, name: "Supervisor Two", activated: false) }
  let!(:trainee) { create(:user, :trainee) }
  let!(:course) { create(:course) }
  # Nối supervisor1 với course để test action `show` và `delete_user_course`
  let!(:course_supervisor) { create(:course_supervisor, user: supervisor1, course: course) }


  # --- Helper để kiểm tra quyền truy cập của Admin ---
  shared_examples "requires admin access" do |http_method, action, params = {}|
    context "when not logged in" do
      it "redirects to the login page" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in as a supervisor" do
      before { sign_in(supervisor1) }

      it "redirects to the root path" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # --- Bắt đầu test các actions ---

  describe "GET /admin/users" do
    let(:action) { admin_users_path }
    it_behaves_like "requires admin access", :get, admin_users_path

    context "when logged in as an admin" do
      before { sign_in(admin); get action }

      it "returns a successful response and renders index" do
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end

      it "assigns all supervisors to @supervisors" do
        expect(assigns(:supervisors)).to include(supervisor1, supervisor2)
      end
    end
  end

  describe "GET /admin/users/new_supervisor" do
    let(:action) { new_supervisor_admin_users_path }
    it_behaves_like "requires admin access", :get, new_supervisor_admin_users_path

    context "when logged in as an admin" do
      before { sign_in(admin); get action }

      it "returns a successful response and renders new_supervisor" do
        expect(response).to be_successful
        expect(response).to render_template(:new_supervisor)
      end

      it "assigns trainees to @user_trainees" do
        expect(assigns(:user_trainees)).to include(trainee)
      end
    end
  end

  describe "PATCH /admin/users/:id/update_status" do
    it_behaves_like "requires admin access", :patch, update_status_admin_user_path(1)

    context "when logged in as an admin" do
      before { sign_in(admin) }

      it "activates a deactivated supervisor" do
        patch update_status_admin_user_path(supervisor2), params: { activated: true }
        expect(supervisor2.reload.activated?).to be true
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end

  describe "GET /admin/users/:id" do
    it_behaves_like "requires admin access", :get, admin_user_path(1)

    context "when logged in as an admin" do
      before { sign_in(admin) }
      
      it "succeeds for an existing supervisor" do
        get admin_user_path(supervisor1)
        expect(response).to be_successful
        expect(assigns(:user_supervisor)).to eq(supervisor1)
      end

      it "redirects if supervisor does not exist" do
        get admin_user_path(99999)
        expect(flash[:danger]).to be_present
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    it_behaves_like "requires admin access", :patch, admin_user_path(1)

    context "when logged in as an admin" do
      before { sign_in(admin) }

      it "updates the supervisor with valid params" do
        patch admin_user_path(supervisor1), params: { user: { name: "Updated Supervisor" } }
        expect(supervisor1.reload.name).to eq("Updated Supervisor")
        expect(response).to redirect_to(admin_user_path(supervisor1))
      end

      it "fails to update with invalid params and re-renders show" do
        patch admin_user_path(supervisor1), params: { user: { name: "" } }
        expect(supervisor1.reload.name).not_to eq("")
        expect(response).to render_template(:show)
      end
    end
  end

  describe "DELETE /admin/users/:id/delete_user_course" do
    it_behaves_like "requires admin access", :delete, delete_user_course_admin_user_path(1)

    context "when logged in as an admin" do
      before { sign_in(admin) }

      it "deletes the course supervisor association" do
        expect {
          delete delete_user_course_admin_user_path(supervisor1), params: { course_id: course.id }
        }.to change(CourseSupervisor, :count).by(-1)
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(admin_user_path(supervisor1))
      end
    end
  end

  describe "PATCH /admin/users/bulk_deactivate" do
    it_behaves_like "requires admin access", :patch, bulk_deactivate_admin_users_path

    context "when logged in as an admin" do
      before { sign_in(admin) }

      it "flips the status of selected supervisors" do
        patch bulk_deactivate_admin_users_path, params: { supervisor_ids: [supervisor1.id, supervisor2.id] }
        expect(supervisor1.reload.activated?).to be false
        expect(supervisor2.reload.activated?).to be true
      end

      it "shows a danger flash if no supervisors are selected" do
        patch bulk_deactivate_admin_users_path, params: { supervisor_ids: [] }
        expect(flash[:danger]).to be_present
      end
    end
  end

  describe "PATCH /admin/users/add_role_supervisor" do
    it_behaves_like "requires admin access", :patch, add_role_supervisor_admin_users_path

    context "when logged in as an admin" do
      before { sign_in(admin) }

      it "promotes a trainee to supervisor" do
        patch add_role_supervisor_admin_users_path, params: { supervisor_ids: [trainee.id] }
        expect(trainee.reload.supervisor?).to be true
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(new_supervisor_admin_users_path)
      end

      it "does nothing if no trainee is selected" do
        patch add_role_supervisor_admin_users_path, params: { supervisor_ids: [] }
        expect(trainee.reload.trainee?).to be true
        # Controller này không có flash[:danger] cho trường hợp này, chỉ redirect.
        expect(flash[:success]).not_to be_present
      end
    end
  end
end
