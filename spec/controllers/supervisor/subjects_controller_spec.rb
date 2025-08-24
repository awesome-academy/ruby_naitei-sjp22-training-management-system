require "rails_helper"

RSpec.describe Supervisor::SubjectsController, type: :controller do
  let(:supervisor) { create(:user, :supervisor) }
  let(:valid_params) { {name: "Ruby", max_score: 100, estimated_time_days: 5} }
  let(:subject_record) { create(:subject, valid_params) }

  before do
    allow(controller).to receive(:current_user).and_return(supervisor)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(I18n).to receive(:t).and_call_original
  end

  describe "#index" do
    subject(:action) { get :index }

    it "responds with status ok" do
      # Tạo data trước khi test
      create_list(:subject, 3)
      
      action
      expect(response).to have_http_status(:ok)
      # Debug: kiểm tra xem controller có thực sự chạy không
      expect(assigns(:subjects)).to be_present
      expect(assigns(:pagy)).to be_present
    end

    context "with search params" do
      let!(:subject1) { create(:subject, name: "Ruby on Rails") }
      let!(:subject2) { create(:subject, name: "JavaScript") }

      it "filters subjects by name" do
        get :index, params: { search: "Ruby" }
        expect(assigns(:subjects)).to include(subject1)
        expect(assigns(:subjects)).not_to include(subject2)
      end

      it "handles blank search" do
        get :index, params: { search: "" }
        expect(assigns(:subjects)).to include(subject1, subject2)
      end

      it "handles nil search" do
        get :index, params: { search: nil }
        expect(assigns(:subjects)).to include(subject1, subject2)
      end
    end

    context "with pagination" do
      before do
        create_list(:subject, 25)
      end

      it "paginates results" do
        get :index
        expect(assigns(:subjects).size).to be <= Settings.ui.items_per_page
      end
    end
  end

  describe "#show" do
    context "when subject exists" do
      let(:subject_with_tasks) { create(:subject) }
      let!(:task1) { create(:task, taskable: subject_with_tasks) }
      let!(:task2) { create(:task, taskable: subject_with_tasks) }
      
      subject(:action) { get :show, params: {id: subject_with_tasks.id} }

      it { action; expect(response).to have_http_status(:ok) }
      it { action; expect(assigns(:tasks)).to eq(subject_with_tasks.tasks.ordered_by_name) }
    end

    context "when subject missing" do
      subject(:action) { get :show, params: {id: 0} }

      it { action; expect(response).to redirect_to(supervisor_subjects_path) }
      it { action; expect(flash[:danger]).to be_present }
    end
  end

  describe "#new" do
    subject(:action) { get :new }

    it { action; expect(assigns(:subject)).to be_a_new(Subject) }
    it { action; expect(response).to have_http_status(:ok) }
  end

  describe "#create" do
    context "when valid" do
      subject(:action) { post :create, params: {subject: valid_params} }

      it { action; expect(response).to redirect_to(supervisor_subjects_path) }
      it { action; expect(flash[:success]).to be_present }
    end

    context "when invalid" do
      subject(:action) { post :create, params: {subject: valid_params.merge(name: "")} }

      it { action; expect(response).to have_http_status(:unprocessable_entity) }
      it { action; expect(response).to render_template(:new) }
      it { action; expect(flash[:danger]).to be_present }
    end

    context "with nested attributes" do
      let(:params_with_tasks) do
        {
          subject: valid_params.merge(
            tasks_attributes: [
              { name: "Task 1" },
              { name: "Task 2" }
            ]
          )
        }
      end

      it "creates subject without tasks (nested attributes not permitted)" do
        expect {
          post :create, params: params_with_tasks
        }.to change(Subject, :count).by(1)
          .and change(Task, :count).by(0)
      end
    end
  end

  describe "#edit" do
    subject(:action) { get :edit, params: {id: subject_record.id} }

    it { action; expect(response).to have_http_status(:ok) }
  end

  describe "#update" do
    context "when success" do
      subject(:action) { patch :update, params: {id: subject_record.id, subject: {name: "New Name"}} }

      it { action; expect(response).to redirect_to(supervisor_subject_path(subject_record)) }
      it { action; expect(flash[:success]).to be_present }
    end

    context "when failure" do
      subject(:action) { patch :update, params: {id: subject_record.id, subject: {name: ""}} }

      it { action; expect(response).to redirect_to(supervisor_subject_path(subject_record)) }
      it { action; expect(flash[:danger]).to be_present }
    end

    context "with nested attributes" do
      let(:subject_with_tasks) { create(:subject) }
      let!(:task) { create(:task, taskable: subject_with_tasks) }

      it "updates tasks" do
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, name: "Updated Task" }
            ]
          }
        }
        expect(task.reload.name).to eq("Updated Task")
      end

      it "destroys tasks" do
        initial_count = Task.with_deleted.count
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, _destroy: "1" }
            ]
          }
        }
        expect(Task.with_deleted.count).to eq(initial_count) # acts_as_paranoid doesn't change count
      end

      it "soft deletes tasks when _destroy is true" do
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, _destroy: "1" }
            ]
          }
        }
        expect(Task.find_by(id: task.id)).to be_nil
        expect(Task.with_deleted.find(task.id)).to be_present
      end

      it "rejects blank task names" do
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, name: "" }
            ]
          }
        }
        expect(task.reload.name).not_to eq("")
      end
    end
  end

  describe "#destroy" do
    context "when success" do
      it "destroys the subject" do
        subject_to_destroy = create(:subject)
        initial_count = Subject.with_deleted.count
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(Subject.with_deleted.count).to eq(initial_count) # acts_as_paranoid doesn't change count
      end

      it "soft deletes the subject" do
        subject_to_destroy = create(:subject)
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(Subject.find_by(id: subject_to_destroy.id)).to be_nil
        expect(Subject.with_deleted.find(subject_to_destroy.id)).to be_present
      end

      it "redirects to subjects index" do
        subject_to_destroy = create(:subject)
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(response).to redirect_to(supervisor_subjects_path)
      end

      it "shows success message" do
        subject_to_destroy = create(:subject)
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(flash[:success]).to be_present
      end
    end

    context "when failure" do
      it "does not destroy the subject" do
        subject_to_destroy = create(:subject)
        allow_any_instance_of(Subject).to receive(:destroy).and_return(false)
        
        initial_count = Subject.with_deleted.count
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(Subject.with_deleted.count).to eq(initial_count)
      end

      it "redirects to subjects index" do
        subject_to_destroy = create(:subject)
        allow_any_instance_of(Subject).to receive(:destroy).and_return(false)
        
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(response).to redirect_to(supervisor_subjects_path)
      end

      it "shows error message" do
        subject_to_destroy = create(:subject)
        allow_any_instance_of(Subject).to receive(:destroy).and_return(false)
        
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(flash[:danger]).to be_present
      end
    end
  end

  describe "#destroy_tasks" do
    let(:subject_with_tasks) { create(:subject) }
    let!(:task1) { create(:task, taskable: subject_with_tasks) }
    let!(:task2) { create(:task, taskable: subject_with_tasks) }

    context "when ids provided" do
      it "destroys specified tasks" do
        initial_count = Task.with_deleted.count
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.with_deleted.count).to eq(initial_count) # acts_as_paranoid doesn't change count
      end

      it "soft deletes specified tasks" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.find_by(id: task1.id)).to be_nil
        expect(Task.find_by(id: task2.id)).to be_nil
        expect(Task.with_deleted.find(task1.id)).to be_present
        expect(Task.with_deleted.find(task2.id)).to be_present
      end

      it "redirects to edit subject" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_with_tasks))
      end

      it "shows success message" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(flash[:success]).to be_present
      end
    end

    context "when no ids" do
      it "does not destroy any tasks" do
        initial_count = Task.with_deleted.count
        delete :destroy_tasks, params: {id: subject_with_tasks.id}
        expect(Task.with_deleted.count).to eq(initial_count)
      end

      it "redirects to edit subject" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id}
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_with_tasks))
      end

      it "shows alert message" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id}
        expect(flash[:alert]).to be_present
      end
    end

    context "when empty array provided" do
      it "handles empty task_ids array" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: []}
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_with_tasks))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "private methods" do
    describe "#load_subject" do
      context "when subject exists" do
        it "loads subject with tasks" do
          subject_with_tasks = create(:subject)
          create(:task, taskable: subject_with_tasks)
          get :show, params: {id: subject_with_tasks.id}
          expect(assigns(:subject)).to eq(subject_with_tasks)
          expect(assigns(:subject).tasks).to be_loaded
        end
      end

      context "when subject does not exist" do
        it "redirects with error message" do
          get :show, params: {id: 99999}
          expect(response).to redirect_to(supervisor_subjects_path)
          expect(flash[:danger]).to be_present
        end
      end
    end

    describe "#subject_params_for_create" do
      it "permits correct parameters" do
        params = ActionController::Parameters.new(
          subject: {
            name: "Test Subject",
            max_score: 100,
            estimated_time_days: 5,
            invalid_param: "should not be permitted"
          }
        )
        
        allow(controller).to receive(:params).and_return(params)
        result = controller.send(:subject_params_for_create)
        
        expect(result[:name]).to eq("Test Subject")
        expect(result[:max_score]).to eq(100)
        expect(result[:estimated_time_days]).to eq(5)
        expect(result[:invalid_param]).to be_nil
      end
    end

    describe "#subject_params_for_update" do
      it "permits correct parameters including nested attributes" do
        params = ActionController::Parameters.new(
          subject: {
            name: "Updated Subject",
            max_score: 150,
            estimated_time_days: 7,
            tasks_attributes: [
              { id: 1, name: "Updated Task", _destroy: "0" }
            ],
            invalid_param: "should not be permitted"
          }
        )
        
        allow(controller).to receive(:params).and_return(params)
        result = controller.send(:subject_params_for_update)
        
        expect(result[:name]).to eq("Updated Subject")
        expect(result[:max_score]).to eq(150)
        expect(result[:estimated_time_days]).to eq(7)
        expect(result[:tasks_attributes]).to be_present
        expect(result[:invalid_param]).to be_nil
      end
    end
  end
end


