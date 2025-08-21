# spec/requests/users_spec.rb

require "rails_helper"

RSpec.describe "Users", type: :request do
  # Tạo sẵn user để test các action cần đăng nhập và có đối tượng
  let!(:user) { create(:user, name: "Example User", email: "user@example.com") }
  # Tạo một user khác để test quyền truy cập
  let!(:other_user) { create(:user, name: "Other User", email: "other@example.com") }

  describe "GET /signup" do
    it "renders the new template successfully" do
      get signup_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end

    it "redirects to root path if user is already logged in" do
      sign_in(user) # Giả sử bạn có helper `sign_in`
      get signup_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /signup" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          name: "New User",
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123",
          birthday: "2000-01-01",
          gender: "male"
        }
      end

      it "creates a new user" do
        expect do
          post signup_path, params: { user: valid_attributes }
        end.to change(User, :count).by(1)
      end

      it "sends an activation email" do
        # Đảm bảo ActiveJob được cấu hình adapter :test
        expect do
          post signup_path, params: { user: valid_attributes }
        end.to have_enqueued_mail(UserMailer, :account_activation)
      end

      it "redirects to the root url with a flash message" do
        post signup_path, params: { user: valid_attributes }
        expect(flash[:info]).to be_present
        expect(response).to redirect_to(root_url)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          name: "",
          email: "user@invalid",
          password: "foo",
          password_confirmation: "bar"
        }
      end

      it "does not create a new user" do
        expect do
          post signup_path, params: { user: invalid_attributes }
        end.not_to change(User, :count)
      end

      it "re-renders the 'new' template with an unprocessable_entity status" do
        post signup_path, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /users/:id (show)" do
    # Action này yêu cầu đăng nhập (dựa vào `logged_in_user` trong ApplicationController)
    it "renders the show template if logged in" do
      sign_in(user)
      get user_path(user)
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
    end

    it "redirects to login page if not logged in" do
      get user_path(user)
      expect(response).to redirect_to(login_path) # Giả sử đường dẫn đăng nhập là `login_path`
    end
  end

  describe "GET /users/:id/edit" do
    it "renders the edit template for the correct user" do
      sign_in(user)
      get edit_user_path(user)
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "redirects if logged in as the wrong user" do
      sign_in(other_user)
      get edit_user_path(user)
      expect(flash[:danger]).to be_present # Giả sử `correct_user` có flash message
      expect(response).to redirect_to(root_path)
    end

    it "redirects if not logged in" do
      get edit_user_path(user)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "PATCH /users/:id (update)" do
    context "when logged in as the correct user" do
      before { sign_in(user) }

      context "with valid parameters" do
        let(:new_attributes) { { name: "Updated Name" } }

        it "updates the user" do
          patch user_path(user), params: { user: new_attributes }
          user.reload
          expect(user.name).to eq("Updated Name")
        end

        it "redirects to the user's show page with a success flash" do
          patch user_path(user), params: { user: new_attributes }
          expect(flash[:success]).to be_present
          expect(response).to redirect_to(user_path(user))
        end
      end

      context "with invalid parameters" do
        let(:invalid_attributes) { { email: "not-an-email" } }

        it "does not update the user" do
          original_email = user.email
          patch user_path(user), params: { user: invalid_attributes }
          user.reload
          expect(user.email).to eq(original_email)
        end

        it "re-renders the 'edit' template with an unprocessable_entity status" do
          patch user_path(user), params: { user: invalid_attributes }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when logged in as the wrong user" do
      it "does not update the user and redirects" do
        sign_in(other_user)
        patch user_path(user), params: { user: { name: "Hijacked!" } }
        user.reload
        expect(user.name).not_to eq("Hijacked!")
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
