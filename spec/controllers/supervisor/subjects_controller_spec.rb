# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supervisor::SubjectsController do
  let!(:supervisor) {create(:user, :supervisor)}
  let!(:subject_record) {
    create(:subject)
  } # Đổi tên biến để tránh xung đột với RSpec 'subject'
  let!(:task_for_subject) {
    create(:task, :with_subject,taskable: subject_record)
  }
  # Giả sử Subject::SUBJECT_PERMITTED_PARAMS_CREATE định nghĩa :name và :description
  let(:valid_params) {attributes_for(:subject)}
  let(:invalid_params) {{name: ""}} # Giả sử name là trường bắt buộc

  before {sign_in supervisor}

  describe "Authentication and Authorization" do
    before {sign_out supervisor}

    context "when user is not signed in" do
      let(:sign_in_path_regex) {%r{/users/sign_in(\?.*)?}}

      it "redirects to the sign in page for index action" do
        get :index
        expect(response).to redirect_to(sign_in_path_regex)
      end

      it "redirects to the sign in page for create action" do
        post :create, params: {subject: valid_params}
        expect(response).to redirect_to(sign_in_path_regex)
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

  describe "before_action :load_subject" do
    context "when the subject is found" do
      before {get :show, params: {id: subject_record.id}}

      it "assigns @subject" do
        expect(assigns(:subject)).to eq(subject_record)
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when the subject is not found" do
      before {get :show, params: {id: -1}}

      it "redirects to the index page" do
        expect(response).to redirect_to(supervisor_subjects_path)
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found_subject"))
      end
    end
  end

  describe "GET #index" do
    let!(:subject_alpha) {create(:subject, name: "Alpha Subject")}
    let!(:subject_beta) {create(:subject, name: "Beta Subject")}
    let!(:older_subject) {
      create(:subject, created_at: 1.day.ago)
    }

    it "assigns @pagy" do
      get :index
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    it "assigns subjects to @subjects, ordered by recent" do
      get :index
      expected_subjects = [subject_record, subject_alpha, subject_beta,
                           older_subject].sort_by(&:created_at).reverse
      expect(assigns(:subjects).to_a).to eq(expected_subjects.take(Settings.ui.items_per_page))
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    context "with search params" do
      before do
        get :index, params: {search: "Alpha"}
      end
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}
      
      before do
        # Tạo thêm subjects để test pagination (sử dụng tên unique)
        @additional_subjects = []
        25.times do |i|
          @additional_subjects << create(:subject, name: "Test Subject #{Time.current.to_f}-#{i}")
        end
        get :index, params: {page: page}
      end

      it "assigns the correct number of items per page" do
        expect(assigns(:subjects).count).to eq(per_page)
      end

      it "assigns the correct page of items" do
        all_subjects_sorted = Subject.all.recent
        expected_paginated_subjects = all_subjects_sorted.limit(per_page).offset((page - 1) * per_page)
        # So sánh array thay vì ActiveRecord::Relation để tránh lỗi object_id
        expect(assigns(:subjects).to_a).to eq(expected_paginated_subjects.to_a)
      end
    end
  end

  describe "GET #show" do
    before {get :show, params: {id: subject_record.id}}

    it "assigns @subject" do
      expect(assigns(:subject)).to eq(subject_record)
    end

    it "assigns @tasks ordered by name" do
      another_task = create(:task, :with_subject, taskable: subject_record,
                            name: "A-Task")
      yet_another_task = create(:task, :with_subject, taskable: subject_record,
                                name: "Z-Task")
      expected_tasks = [task_for_subject, another_task,
yet_another_task].sort_by(&:name)
      expect(assigns(:tasks).to_a).to eq(expected_tasks)
    end

    it "renders the show template" do
      expect(response).to render_template(:show)
    end
  end

  describe "GET #new" do
    before {get :new}

    it "assigns a new subject" do
      expect(assigns(:subject)).to be_a_new(Subject)
    end

    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Subject" do
        expect {post :create, params: {subject: valid_params}
        }.to change(Subject, :count).by(1)
      end

      context "after a valid submission" do
        before {post :create, params: {subject: valid_params}}

        it "redirects to the index page" do
          expect(response).to redirect_to(supervisor_subjects_path)
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("supervisor.subjects.create.create_success"))
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a new Subject" do
        expect {post :create, params: {subject: invalid_params}
        }.not_to change(Subject, :count)
      end

      context "after an invalid submission" do
        before {post :create, params: {subject: invalid_params}}

        it "renders the new template" do
          expect(response).to render_template(:new)
        end

        it "returns an unprocessable entity status" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "sets a danger flash message" do
          expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.create.create_failed"))
        end
      end
    end
  end

  describe "GET #edit" do
    before {get :edit, params: {id: subject_record.id}}

    it "assigns the subject" do
      expect(assigns(:subject)).to eq(subject_record)
    end

    it "renders the edit template" do
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    let(:new_name) {"Updated Subject Name"}
    # Giả sử Subject::SUBJECT_PERMITTED_PARAMS_UPDATE định nghĩa :name
    let(:update_valid_params) {{name: new_name}}
    let(:update_invalid_params) {{name: ""}}

    context "with valid parameters" do
      before {
        patch :update,
              params: {id: subject_record.id,
                       subject: update_valid_params}
      }

      it "updates the requested subject" do
        expect(subject_record.reload.name).to eq(new_name)
      end

      it "redirects to the subject's show page" do
        expect(response).to redirect_to(supervisor_subject_path(subject_record))
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("supervisor.subjects.update.update_success", subject_name: new_name))
      end
    end

    context "with invalid parameters" do
      before {
        patch :update,
              params: {id: subject_record.id,
                       subject: update_invalid_params}
      }

      it "does not update the subject" do
        expect(subject_record.reload.name).not_to eq("")
      end

      it "redirects to the subject's show page" do
        expect(response).to redirect_to(supervisor_subject_path(subject_record))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to be_present
      end
    end
  end

  describe "DELETE #destroy" do
    context "when destroy succeeds" do
      it "removes the subject" do
        expect {delete :destroy, params: {id: subject_record.id}
        }.to change(Subject, :count).by(-1)
      end

      context "after successful deletion" do
        before {delete :destroy, params: {id: subject_record.id}}

        it "redirects to the index page" do
          expect(response).to redirect_to(supervisor_subjects_path)
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("supervisor.subjects.destroy.subject_deleted"))
        end
      end
    end

    context "when destroy fails" do
      before {allow_any_instance_of(Subject).to receive(:destroy).and_return(false)}

      it "does not remove the subject" do
        expect {delete :destroy, params: {id: subject_record.id}
        }.not_to change(Subject, :count)
      end

      it "sets a danger flash message" do
        delete :destroy, params: {id: subject_record.id}
        expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.destroy.delete_failed"))
      end

      it "redirects to the index page" do
        delete :destroy, params: {id: subject_record.id}
        expect(response).to redirect_to(supervisor_subjects_path)
      end
    end
  end

  describe "DELETE #destroy_tasks" do
    let!(:task1) {create(:task, :with_subject, taskable: subject_record)}
    let!(:task2) {create(:task, :with_subject, taskable: subject_record)}
    let!(:task_from_other_subject) {create(:task, :with_subject)}

    context "when task_ids are provided" do
      it "removes selected tasks" do
        expect {delete :destroy_tasks,
                params: {id: subject_record.id,
                         task_ids: [task1.id, task2.id]}
        }.to change(Task, :count).by(-2)
      end

      context "after successful task deletion" do
        before {
          delete :destroy_tasks,
                 params: {id: subject_record.id,
                          task_ids: [task1.id]}
        }

        it "redirects to the edit page" do
          expect(response).to redirect_to(edit_supervisor_subject_path(subject_record))
        end

        it "sets a success flash message" do
          expect(flash[:success]).to eq(I18n.t("supervisor.subjects.destroy_tasks.n_tasks_deleted", count: 1))
        end
      end

      it "does not destroy tasks from other subjects" do
        expect {delete :destroy_tasks,
                        params: {id: subject_record.id,
                                 task_ids: [task_from_other_subject.id]}
        }.not_to change(Task, :count)
      end
    end

    context "when no task_ids are provided" do
      before {
        delete :destroy_tasks,
                params: {id: subject_record.id, task_ids: []}
      }

      it "does not remove any tasks" do
        expect {delete :destroy_tasks,
                        params: {id: subject_record.id, task_ids: []}
        }.not_to change(Task, :count)
      end

      it "redirects to the edit page" do
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_record))
      end

      it "sets an alert flash message" do
        expect(flash[:alert]).to eq(I18n.t("supervisor.subjects.destroy_tasks.no_tasks_to_delete"))
      end
    end
  end
end
