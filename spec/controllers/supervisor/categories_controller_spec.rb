# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supervisor::CategoriesController do
  let!(:supervisor) {create(:user, :supervisor)}
  let!(:category) {create(:category)}
  let(:valid_params) {attributes_for(:category)}
  let(:invalid_params) {{name: ""}}

  before {sign_in supervisor}

  describe "Authentication and Authorization" do
    before {sign_out supervisor}

    context "when user is not signed in" do
      it "redirects to the sign in page for index action" do
        get :index
        expect(response).to redirect_to(%r{/users/sign_in})
      end

      it "redirects to the sign in page for create action" do
        post :create, params: {category: valid_params}
        expect(response).to redirect_to(%r{/users/sign_in})
      end
    end

    context "when user is signed in but not a supervisor" do
      let(:trainee) {create(:user, :trainee)}
      before do
        sign_in trainee
        get :index
      end

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("messages.permission_denied"))
      end
    end
  end

  describe "before_action :load_category" do
    context "when the category is found" do
      before {get :show, params: {id: category.id}}

      it "assigns @category" do
        expect(assigns(:category)).to eq(category)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when the category is not found" do
      before {get :show, params: {id: -1}}

      it "redirects to the index page" do
        expect(response).to redirect_to(supervisor_categories_path)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found_category"))
      end
    end
  end

  describe "GET #index" do
    let!(:category2) {create(:category, name: "Alpha")}
    let!(:category3) {create(:category, name: "Beta")}
    before {get :index}

    it "assigns @pagy" do
      expect(assigns(:pagy)).to be_present
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}

      before do
        20.times {create(:category)}
        get :index, params: {page: page}
      end

      it "assigns the correct number of items per page" do
        expect(assigns(:categories).count).to eq(per_page)
      end

      it "assigns the correct page of items" do
        expected_categories = Category.all.recent.limit(per_page).offset((page - 1) * per_page)
        expect(assigns(:categories)).to match_array(expected_categories)
      end
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    context "with search params" do
      before {get :index, params: {search: "Alpha"}}

      it "filters categories based on search query" do
        expect(assigns(:categories)).to contain_exactly(category2)
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Category" do
        expect {post :create, params: {category: valid_params}
        }.to change(Category, :count).by(1)
      end

      context "after a valid submission" do
        before {post :create, params: {category: valid_params}}

        it "redirects to the index page" do
          expect(response).to redirect_to(supervisor_categories_path)
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("supervisor.categories.create.create_success"))
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a new Category" do
        expect {post :create, params: {category: invalid_params}
        }.not_to change(Category, :count)
      end

      context "after an invalid submission" do
        before {post :create, params: {category: invalid_params}}

        it "renders the new template" do
          expect(response).to render_template(:new)
        end

        it "returns an unprocessable entity status" do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:new_name) {"Updated name"}

    context "with valid parameters" do
      before {
        patch :update,
              params: {id: category.id,
                       category: {name: new_name}}
      }

      it "updates the requested category" do
        expect(category.reload.name).to eq(new_name)
      end

      it "redirects to the category" do
        expect(response).to redirect_to(supervisor_category_path(category))
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("supervisor.categories.update.update_success"))
      end
    end

    context "with invalid parameters" do
      before {
        patch :update,
              params: {id: category.id,
                       category: {name: ""}}
      }

      it "does not update the category" do
        expect(category.reload.name).not_to eq("")
      end

      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end

      it "returns an unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when destroy succeeds" do
      it "removes the category" do
        expect {delete :destroy, params: {id: category.id}
        }.to change(Category, :count).by(-1)
      end

      context "after successful deletion" do
        before {delete :destroy, params: {id: category.id}}

        it "redirects to the index page" do
          expect(response).to redirect_to(supervisor_categories_path)
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("supervisor.categories.destroy.category_deleted"))
        end
      end
    end

    context "when destroy fails" do
      before {allow_any_instance_of(Category).to receive(:destroy).and_return(false)
      }

      it "does not remove the category" do
        expect {delete :destroy, params: {id: category.id}}.not_to change(Category, :count)
      end

      it "sets a danger flash message" do
        delete :destroy, params: {id: category.id}
        expect(flash[:danger]).to eq(I18n.t("supervisor.categories.destroy.delete_failed"))
      end
    end
  end

  describe "GET #new" do
    before {get :new}

    it "assigns a new category" do
      expect(assigns(:category)).to be_a_new(Category)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    before {get :edit, params: {id: category.id}}

    it "assigns the category" do
      expect(assigns(:category)).to eq(category)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end
end
