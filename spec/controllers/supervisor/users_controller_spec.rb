# spec/requests/supervisor/users_spec.rb

require "rails_helper"

RSpec.describe "Supervisor::Users", type: :request do
  # --- Khai báo các đối tượng chính ---
  let!(:supervisor) { create(:user, :supervisor) }
  let!(:trainee1) { create(:user, :trainee, name: "Alice Smith", activated: true) }
  let!(:trainee2) { create(:user, :trainee, name: "Bob Johnson", activated: false) }
  let!(:course) { create(:course) }
  let!(:user_course) { create(:user_course, user: trainee1, course: course, status: :in_progress) }

  # --- Helper để kiểm tra quyền truy cập ---
  shared_examples "requires supervisor access" do |http_method, action, params = {}|
    context "when not logged in" do
      it "redirects to the login page" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in as a trainee" do
      before { sign_in(trainee1) }

      it "redirects to the root path" do
        public_send(http_method, action, params: params)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # --- Bắt đầu test các actions ---

  describe "GET /supervisor/users" do
    let(:action) { supervisor_users_path }

    it_behaves_like "requires supervisor access", :get, supervisor_users_path

    context "when logged in as a supervisor" do
      before do
        sign_in(supervisor)
        get action
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template(:index)
      end

      it "assigns all trainees to @trainees" do
        expect(assigns(:trainees)).to include(trainee1, trainee2)
      end
    end
  end

  describe "GET /supervisor/users/:id" do
    let(:action) { supervisor_user_path(trainee1) }

    it_behaves_like "requires supervisor access", :get, supervisor_users_path(1) # Dùng ID giả

    context "when logged in as a supervisor" do
      before do
        sign_in(supervisor)
        get action
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "assigns the correct trainee to @user_trainee" do
        expect(assigns(:user_trainee)).to eq(trainee1)
      end

      it "assigns the trainee's courses to @trainee_courses" do
        expect(assigns(:trainee_courses)).to include(course)
      end
    end
  end

  describe "PATCH /supervisor/users/:id/update_status" do
    let(:action) { update_status_supervisor_user_path(trainee1) }

    it_behaves_like "requires supervisor access", :patch, update_status_supervisor_user_path(1)

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      it "activates a deactivated user" do
        patch update_status_supervisor_user_path(trainee2), params: { activated: true }
        expect(trainee2.reload.activated?).to be true
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(supervisor_users_path)
      end

      it "deactivates an activated user" do
        patch action, params: { activated: false }
        expect(trainee1.reload.activated?).to be false
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "PATCH /supervisor/users/bulk_deactivate" do
    let(:action) { bulk_deactivate_supervisor_users_path }

    it_behaves_like "requires supervisor access", :patch, bulk_deactivate_supervisor_users_path

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      it "flips the status of selected trainees" do
        patch action, params: { trainee_ids: [trainee1.id, trainee2.id] }
        expect(trainee1.reload.activated?).to be false
        expect(trainee2.reload.activated?).to be true
        expect(flash[:success]).to match(/2/) # Kiểm tra message có số 2
      end

      it "shows a danger flash if no trainees are selected" do
        patch action, params: { trainee_ids: [] }
        expect(flash[:danger]).to be_present
        expect(response).to redirect_to(supervisor_users_path)
      end
    end
  end

  describe "PATCH /supervisor/users/:id/update_user_course_status" do
    let(:action) { update_user_course_status_supervisor_user_path(trainee1) }

    it_behaves_like "requires supervisor access", :patch, update_user_course_status_supervisor_user_path(1)

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      it "updates the user_course status" do
        patch action, params: { course_id: course.id, status: :finished }
        expect(user_course.reload.status).to eq("finished")
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(supervisor_user_path(trainee1))
      end
    end
  end

  describe "DELETE /supervisor/users/:id/delete_user_course" do
    let(:action) { delete_user_course_supervisor_user_path(trainee1) }

    it_behaves_like "requires supervisor access", :delete, delete_user_course_supervisor_user_path(1)

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      it "deletes the user_course association" do
        expect do
          delete action, params: { course_id: course.id }
        end.to change(UserCourse, :count).by(-1)
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(supervisor_user_path(trainee1))
      end
    end
  end

  describe "PATCH /supervisor/users/:id/update" do
    let(:action) { supervisor_user_path(trainee1) }
    let(:valid_params) { { user: { name: "New Trainee Name" } } }
    let(:invalid_params) { { user: { name: "" } } }

    it_behaves_like "requires supervisor access", :patch, supervisor_users_path(1)

    context "when logged in as a supervisor" do
      before { sign_in(supervisor) }

      context "with valid parameters" do
        it "updates the trainee's attributes" do
          patch action, params: valid_params
          expect(trainee1.reload.name).to eq("New Trainee Name")
          expect(flash[:success]).to be_present
          expect(response).to redirect_to(supervisor_user_path(trainee1))
        end
      end

      context "with invalid parameters" do
        it "does not update the trainee and re-renders show" do
          patch action, params: invalid_params
          expect(trainee1.reload.name).to eq("Alice Smith")
          expect(flash[:danger]).to be_present
          expect(response).to render_template(:show)
        end
      end
    end
  end
end
