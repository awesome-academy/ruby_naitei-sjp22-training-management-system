# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supervisor::TasksController do
  let!(:supervisor) {create(:user, :supervisor)}
  let!(:subject) {create(:subject)}
  let!(:task) {create(:task, taskable: subject)}
  let(:valid_params) do
    attributes_for(:task, taskable_type: Subject.name,
                  taskable_id: subject.id)
  end

  before {sign_in supervisor}

  describe "authentication and authorization" do
    before {sign_out supervisor}

    context "when user is not signed in" do
      it "redirects to login page for index" do
        get :index
        expect(response).to redirect_to(/\/users\/sign_in/)
      end

      it "redirects to login page for create" do
        post :create,
             params: {task: attributes_for(:task, taskable_type: Subject.name,
             taskable_id: subject.id)}
        expect(response).to redirect_to(/\/users\/sign_in/)
      end
    end

    context "when user is signed in but not supervisor" do
      let!(:normal_user) {create(:user, :trainee)}

      before {sign_in normal_user}

      context "GET #index" do
        before {get :index}

        it "redirects to root path" do
          expect(response).to redirect_to(root_path)
        end

        it "sets danger flash" do
          expect(flash[:danger]).to eq(I18n.t("messages.permission_denied"))
        end
      end

      context "POST #create" do
        let(:task_params) do
          attributes_for(:task, taskable_type: Subject.name,
                         taskable_id: subject.id)
        end
        before {post :create, params: {task: task_params}}

        it "redirects to root path" do
          expect(response).to redirect_to(root_path)
        end

        it "sets danger flash" do
          expect(flash[:danger]).to eq(I18n.t("messages.permission_denied"))
        end
      end
    end
  end

  describe "before_action :load_task" do
    context "when task is found" do
      before {get :show, params: {id: task.id}}

      it "assigns @task" do
        expect(assigns(:task)).to eq(task)
      end
    end

    context "when task is not found" do
      let(:invalid_id) {-1}

      context "GET #show" do
        before {get :show, params: {id: invalid_id}}

        it "redirects" do
          expect(response).to redirect_to(supervisor_tasks_path)
        end

        it "sets flash" do
          expect(flash[:danger]).to eq(I18n.t("not_found_task"))
        end
      end

      context "DELETE #destroy" do
        before {delete :destroy, params: {id: invalid_id}}

        it "redirects" do
          expect(response).to redirect_to(supervisor_tasks_path)
        end

        it "sets flash" do
          expect(flash[:danger]).to eq(I18n.t("not_found_task"))
        end
      end

      context "GET #edit" do
        before {get :edit, params: {id: invalid_id}}

        it "redirects" do
          expect(response).to redirect_to(supervisor_tasks_path)
        end

        it "sets flash" do
          expect(flash[:danger]).to eq(I18n.t("not_found_task"))
        end
      end

      context "PATCH #update" do
        before do
          patch :update,
                params: {id: invalid_id, task: {name: "New Name"}}
        end

        it "redirects" do
          expect(response).to redirect_to(supervisor_tasks_path)
        end

        it "sets flash" do
          expect(flash[:danger]).to eq(I18n.t("not_found_task"))
        end
      end
    end
  end

  describe "GET #index" do
    let!(:another_subject) {create(:subject)}
    let!(:task1) {create(:task, name: "Task Alpha", taskable: subject)}
    let!(:task2) {create(:task, name: "Task Beta", taskable: subject)}
    let!(:task3) do
      create(:task, name: "Other Task", taskable: another_subject)
    end

    context "without filters" do
      before {get :index}

      it "assigns @pagy" do
        expect(assigns(:pagy)).to be_present
      end

      it "assigns @tasks" do
        expect(assigns(:tasks)).to include(task1, task2, task3)
      end

      it "renders index template" do
        expect(response).to render_template(:index)
      end
    end

    context "with subject_id filter" do
      before {get :index, params: {subject_id: subject.id}}

      it "includes tasks belonging to the specified subject" do
        expect(assigns(:tasks)).to include(task1, task2)
      end

      it "excludes tasks not belonging to the specified subject" do
        expect(assigns(:tasks)).not_to include(task3)
      end
    end

    context "with search query" do
      before {get :index, params: {search: "Alpha"}}

      it "filters by search query" do
        expect(assigns(:tasks)).to contain_exactly(task1)
      end
    end

    context "with subject_id and search query" do
      before {get :index, params: {subject_id: subject.id, search: "Beta"}}

      it "filters correctly" do
        expect(assigns(:tasks)).to contain_exactly(task2)
      end
    end

    context "query chain" do
      it "calls correct query chain" do
        expect(Task).to receive_message_chain(:for_taskable_type, :includes,
                                              :recent, :by_subject, :search_by_name).and_return(Task.all)
        get :index, params: {search: :taskable}
      end
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}

      before do
        20.times {create(:task, :with_subject)}
        get :index, params: {page: page}
      end

      it "assigns the correct number of items per page" do
        expect(assigns(:tasks).count).to eq(per_page)
      end

      it "assigns the correct page of items" do
        expected_tasks = Task.all.recent.limit(per_page).offset((page - 1) * per_page)
        expect(assigns(:tasks)).to match_array(expected_tasks)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when destroy succeeds" do
      before {delete :destroy, params: {id: task.id}}

      it "removes the task" do
        expect(Task.exists?(task.id)).to be_falsey
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("supervisor.tasks.destroy.task_deleted"))
      end

      it "redirects to index" do
        expect(response).to redirect_to(supervisor_tasks_path)
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Task).to receive(:destroy).and_return(false)
        delete :destroy, params: {id: task.id}
      end

      it "does not remove the task" do
        expect(Task.exists?(task.id)).to be_truthy
      end

      it "sets danger flash" do
        expect(flash[:danger]).to eq(I18n.t("supervisor.tasks.destroy.delete_failed"))
      end

      it "redirects to index" do
        expect(response).to redirect_to(supervisor_tasks_path)
      end
    end
  end

  describe "GET #new" do
    before {get :new}

    it "assigns @task" do
      expect(assigns(:task)).to be_a_new(Task)
    end

    it "renders new template" do
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      attributes_for(:task, taskable_type: Subject.name,
                    taskable_id: subject.id)
    end
    let(:invalid_params) do
      attributes_for(:task, name: "", taskable_type: Subject.name,
                    taskable_id: subject.id)
    end

    context "with valid params" do
      it "creates task" do
        expect do
          post :create, params: {task: valid_params}
        end.to change(Task, :count).by(1)
      end

      context "after request" do
        before {post :create, params: {task: valid_params}}

        it "sets success flash" do
          expect(flash[:success]).to eq(I18n.t("supervisor.tasks.create.create_success"))
        end

        it "redirects to index" do
          expect(response).to redirect_to(supervisor_tasks_path)
        end

        it "creates task with correct attributes" do
          created_task = Task.last
          valid_params.each do |key, value|
            expect(created_task.send(key)).to eq(value)
          end
        end

        it "does not allow unpermitted params" do
          post :create,
               params: {task: valid_params.merge(unpermitted_field: "hack")}
          task.reload
          expect(task.respond_to?(:unpermitted_field)).to be_falsey
        end
      end
    end

    context "with invalid params" do
      before {post :create, params: {task: invalid_params}}

      it "does not create task" do
        expect(Task.count).to eq(1)
      end

      it "renders new template" do
        expect(response).to render_template(:new)
      end

      it "returns unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets danger flash" do
        expect(flash.now[:danger]).to eq(I18n.t("supervisor.tasks.create.create_fail"))
      end
    end
  end

  describe "GET #show" do
    it "assigns @task" do
      get :show, params: {id: task.id}
      expect(assigns(:task)).to eq(task)
    end
  end

  describe "GET #edit" do
    before {get :edit, params: {id: task.id}}

    it "assigns @task" do
      expect(assigns(:task)).to eq(task)
    end

    it "renders edit template" do
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    let(:new_name) {"Updated Task Name"}

    context "with valid params" do
      before do
        patch :update, params: {id: task.id, task: {name: new_name}}
      end

      it "updates task" do
        expect(task.reload.name).to eq(new_name)
      end

      it "sets success flash" do
        expect(flash[:success]).to eq(I18n.t("supervisor.tasks.update.update_success"))
      end

      it "redirects to index" do
        expect(response).to redirect_to(supervisor_tasks_path)
      end

      it "updates the task's name" do
        expect(task.reload.name).to eq(new_name)
      end

      it "does not change the taskable type" do
        expect(task.reload.taskable_type).to eq(task.taskable_type)
      end

      it "does not change the taskable ID" do
        expect(task.reload.taskable_id).to eq(task.taskable_id)
      end

      it "does not allow unpermitted params" do
        patch :update,
              params: {id: task.id,
                       task: valid_params.merge(unpermitted_field: "hack")}
        task.reload
        expect(task.respond_to?(:unpermitted_field)).to be_falsey
      end
    end

    context "with invalid params" do
      let(:original_name) {task.name}

      before {patch :update, params: {id: task.id, task: {name: ""}}}

      it "does not update task" do
        expect(task.reload.name).to eq(original_name)
      end

      it "renders new template" do
        expect(response).to render_template(:new)
      end

      it "returns unprocessable_entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets danger flash" do
        expect(flash.now[:danger]).to eq(I18n.t("supervisor.tasks.update.update_fail"))
      end
    end
  end
end
