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

    before do
      create_list(:subject, 3)
    end

    it "responds with status ok" do
      action
      expect(response).to have_http_status(:ok)
    end

    it "assigns subjects" do
      action
      expect(assigns(:subjects)).to be_present
    end

    it "assigns correct number of subjects" do
      action
      expect(assigns(:subjects).count).to eq(3)
    end

    it "assigns first subject with correct type" do
      action
      expect(assigns(:subjects).first).to be_a(Subject)
    end

    it "assigns last subject with correct type" do
      action
      expect(assigns(:subjects).last).to be_a(Subject)
    end

    it "assigns pagy" do
      action
      expect(assigns(:pagy)).to be_present
    end

    it "assigns pagy with correct count" do
      action
      expect(assigns(:pagy).count).to eq(3)
    end

    it "assigns pagy with correct items per page" do
      action
      expect(assigns(:pagy).vars[:items]).to eq(Settings.ui.items_per_page)
    end

    it "assigns pagy with correct page number" do
      action
      expect(assigns(:pagy).page).to eq(1)
    end

    it "assigns pagy with correct total pages" do
      action
      expect(assigns(:pagy).pages).to eq(1)
    end

    context "with search params" do
      let!(:subject1) { create(:subject, name: "Ruby on Rails") }
      let!(:subject2) { create(:subject, name: "JavaScript") }

      it "includes matching subject" do
        get :index, params: { search: "Ruby" }
        expect(assigns(:subjects)).to include(subject1)
      end

      it "excludes non-matching subject" do
        get :index, params: { search: "Ruby" }
        expect(assigns(:subjects)).not_to include(subject2)
      end

      it "includes all subjects with blank search" do
        get :index, params: { search: "" }
        expect(assigns(:subjects)).to include(subject1, subject2)
      end

      it "includes all subjects with nil search" do
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

      it "responds with status ok" do
        action
        expect(response).to have_http_status(:ok)
      end

      it "assigns tasks" do
        action
        expect(assigns(:tasks)).to eq(subject_with_tasks.tasks.ordered_by_name)
      end

      it "assigns correct number of tasks" do
        action
        expect(assigns(:tasks).count).to eq(2)
      end

      it "assigns first task with correct type" do
        action
        expect(assigns(:tasks).first).to be_a(Task)
      end

      it "assigns last task with correct type" do
        action
        expect(assigns(:tasks).last).to be_a(Task)
      end
    end

    context "when subject missing" do
      subject(:action) { get :show, params: {id: 0} }

      it "redirects to subjects index" do
        action
        expect(response).to redirect_to(supervisor_subjects_path)
      end

      it "shows error message with correct I18n key" do
        action
        expect(flash[:danger]).to eq(I18n.t("not_found_subject"))
      end
    end
  end

  describe "#new" do
    subject(:action) { get :new }

    it "assigns new subject" do
      action
      expect(assigns(:subject)).to be_a_new(Subject)
    end

    it "responds with status ok" do
      action
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#create" do
    context "when valid" do
      subject(:action) { post :create, params: {subject: valid_params} }

      it "redirects to subjects index" do
        action
        expect(response).to redirect_to(supervisor_subjects_path)
      end

      it "shows success message" do
        action
        expect(flash[:success]).to be_present
      end

      it "creates subject with correct name" do
        action
        created_subject = Subject.last
        expect(created_subject.name).to eq(valid_params[:name])
      end

      it "creates subject with correct max_score" do
        action
        created_subject = Subject.last
        expect(created_subject.max_score).to eq(valid_params[:max_score])
      end

      it "creates subject with correct estimated_time_days" do
        action
        created_subject = Subject.last
        expect(created_subject.estimated_time_days).to eq(valid_params[:estimated_time_days])
      end
    end

    context "when invalid" do
      subject(:action) { post :create, params: {subject: valid_params.merge(name: "")} }

      it "responds with unprocessable entity status" do
        action
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new template" do
        action
        expect(response).to render_template(:new)
      end

      it "shows error message with correct I18n key" do
        action
        expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.create.create_failed"))
      end
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

      it "creates subject without tasks" do
        expect {
          post :create, params: params_with_tasks
        }.to change(Subject, :count).by(1)
      end

      it "does not create tasks" do
        expect {
          post :create, params: params_with_tasks
        }.to change(Task, :count).by(0)
      end
    end
  end

  describe "#edit" do
    subject(:action) { get :edit, params: {id: subject_record.id} }

    it "responds with status ok" do
      action
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#update" do
    context "when success" do
      subject(:action) { patch :update, params: {id: subject_record.id, subject: {name: "New Name"}} }

      it "redirects to subject show" do
        action
        expect(response).to redirect_to(supervisor_subject_path(subject_record))
      end

      it "shows success message" do
        action
        expect(flash[:success]).to eq(I18n.t("supervisor.subjects.update.update_success", subject_name: subject_record.reload.name))
      end

      it "updates subject with correct data" do
        action
        subject_record.reload
        expect(subject_record.name).to eq("New Name")
      end
    end

    context "when failure" do
      subject(:action) { patch :update, params: {id: subject_record.id, subject: {name: ""}} }

      it "redirects to subject show" do
        action
        expect(response).to redirect_to(supervisor_subject_path(subject_record))
      end

      it "shows error message with correct I18n key" do
        action
        expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.update.update_failed"))
      end
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

      it "maintains task count when destroying" do
        initial_count = Task.with_deleted.count
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, _destroy: "1" }
            ]
          }
        }
        expect(Task.with_deleted.count).to eq(initial_count)
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
      end

      it "keeps task in with_deleted when soft deleted" do
        patch :update, params: {
          id: subject_with_tasks.id,
          subject: {
            tasks_attributes: [
              { id: task.id, _destroy: "1" }
            ]
          }
        }
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
      it "maintains subject count" do
        subject_to_destroy = create(:subject)
        initial_count = Subject.with_deleted.count
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(Subject.with_deleted.count).to eq(initial_count)
      end

      it "soft deletes the subject" do
        subject_to_destroy = create(:subject)
        delete :destroy, params: {id: subject_to_destroy.id}
        expect(Subject.find_by(id: subject_to_destroy.id)).to be_nil
      end

      it "keeps subject in with_deleted" do
        subject_to_destroy = create(:subject)
        delete :destroy, params: {id: subject_to_destroy.id}
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
        expect(flash[:success]).to eq(I18n.t("supervisor.subjects.destroy.subject_deleted"))
      end
    end

    context "when failure" do
      it "does not change subject count" do
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
        expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.destroy.delete_failed"))
      end
    end
  end

  describe "#destroy_tasks" do
    let(:subject_with_tasks) { create(:subject) }
    let!(:task1) { create(:task, taskable: subject_with_tasks) }
    let!(:task2) { create(:task, taskable: subject_with_tasks) }

    context "when ids provided" do
      it "maintains task count" do
        initial_count = Task.with_deleted.count
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.with_deleted.count).to eq(initial_count)
      end

      it "soft deletes first task" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.find_by(id: task1.id)).to be_nil
      end

      it "soft deletes second task" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.find_by(id: task2.id)).to be_nil
      end

      it "keeps first task in with_deleted" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.with_deleted.find(task1.id)).to be_present
      end

      it "keeps second task in with_deleted" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(Task.with_deleted.find(task2.id)).to be_present
      end

      it "redirects to edit subject" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_with_tasks))
      end

      it "shows success message" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: [task1.id, task2.id]}
        expect(flash[:success]).to eq(I18n.t("supervisor.subjects.destroy_tasks.n_tasks_deleted", count: 2))
      end
    end

    context "when no ids" do
      it "does not change task count" do
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
        expect(flash[:alert]).to eq(I18n.t("supervisor.subjects.destroy_tasks.no_tasks_to_delete"))
      end
    end

    context "when empty array provided" do
      it "redirects to edit subject" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: []}
        expect(response).to redirect_to(edit_supervisor_subject_path(subject_with_tasks))
      end

      it "shows alert message" do
        delete :destroy_tasks, params: {id: subject_with_tasks.id, task_ids: []}
        expect(flash[:alert]).to eq(I18n.t("supervisor.subjects.destroy_tasks.no_tasks_to_delete"))
      end
    end
  end

  describe "private methods" do
    describe "#load_subject" do
      context "when subject exists" do
        let(:subject_with_tasks) { create(:subject) }

        before do
          create(:task, taskable: subject_with_tasks)
        end

        it "loads subject" do
          get :show, params: {id: subject_with_tasks.id}
          expect(assigns(:subject)).to eq(subject_with_tasks)
        end

        it "loads subject with tasks" do
          get :show, params: {id: subject_with_tasks.id}
          expect(assigns(:subject).tasks).to be_loaded
        end
      end

      context "when subject does not exist" do
        it "redirects to subjects index" do
          get :show, params: {id: 99999}
          expect(response).to redirect_to(supervisor_subjects_path)
        end

        it "shows error message with correct I18n key" do
          get :show, params: {id: 99999}
          expect(flash[:danger]).to eq(I18n.t("not_found_subject"))
        end
      end
    end

    describe "#subject_params_for_create" do
      let(:params) do
        ActionController::Parameters.new(
          subject: {
            name: "Test Subject",
            max_score: 100,
            estimated_time_days: 5,
            invalid_param: "should not be permitted"
          }
        )
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it "permits name parameter" do
        result = controller.send(:subject_params_for_create)
        expect(result[:name]).to eq("Test Subject")
      end

      it "permits max_score parameter" do
        result = controller.send(:subject_params_for_create)
        expect(result[:max_score]).to eq(100)
      end

      it "permits estimated_time_days parameter" do
        result = controller.send(:subject_params_for_create)
        expect(result[:estimated_time_days]).to eq(5)
      end

      it "does not permit invalid parameter" do
        result = controller.send(:subject_params_for_create)
        expect(result[:invalid_param]).to be_nil
      end
    end

    describe "#subject_params_for_update" do
      let(:params) do
        ActionController::Parameters.new(
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
      end

      before do
        allow(controller).to receive(:params).and_return(params)
      end

      it "permits name parameter" do
        result = controller.send(:subject_params_for_update)
        expect(result[:name]).to eq("Updated Subject")
      end

      it "permits max_score parameter" do
        result = controller.send(:subject_params_for_update)
        expect(result[:max_score]).to eq(150)
      end

      it "permits estimated_time_days parameter" do
        result = controller.send(:subject_params_for_update)
        expect(result[:estimated_time_days]).to eq(7)
      end

      it "permits tasks_attributes" do
        result = controller.send(:subject_params_for_update)
        expect(result[:tasks_attributes]).to be_present
      end

      it "does not permit invalid parameter" do
        result = controller.send(:subject_params_for_update)
        expect(result[:invalid_param]).to be_nil
      end
    end
  end

  describe "associations" do
    let(:subject_with_associations) { create(:subject) }
    let!(:task1) { create(:task, taskable: subject_with_associations) }
    let!(:task2) { create(:task, taskable: subject_with_associations) }
    let!(:category) { create(:category) }
    let!(:subject_category) { create(:subject_category, subject: subject_with_associations, category: category) }

    describe "tasks association" do
      it "has correct number of tasks" do
        expect(subject_with_associations.tasks.count).to eq(2)
      end

      it "returns tasks in correct order" do
        expect(subject_with_associations.tasks.ordered_by_name).to eq([task1, task2].sort_by(&:name))
      end

      it "includes correct task objects" do
        expect(subject_with_associations.tasks).to include(task1, task2)
      end

      it "returns tasks with correct type" do
        subject_with_associations.tasks.each do |task|
          expect(task).to be_a(Task)
        end
      end
    end

    describe "subject_categories association" do
      it "has correct number of subject_categories" do
        expect(subject_with_associations.subject_categories.count).to eq(1)
      end

      it "includes correct subject_category object" do
        expect(subject_with_associations.subject_categories).to include(subject_category)
      end

      it "returns subject_categories with correct type" do
        subject_with_associations.subject_categories.each do |subject_category|
          expect(subject_category).to be_a(SubjectCategory)
        end
      end
    end

    describe "categories association" do
      it "has correct number of categories" do
        expect(subject_with_associations.categories.count).to eq(1)
      end

      it "includes correct category object" do
        expect(subject_with_associations.categories).to include(category)
      end

      it "returns categories with correct type" do
        subject_with_associations.categories.each do |category|
          expect(category).to be_a(Category)
        end
      end
    end

    describe "course_subjects association" do
      let!(:course) { create(:course) }
      let!(:course_subject) { create(:course_subject, subject: subject_with_associations, course: course) }

      it "has correct number of course_subjects" do
        expect(subject_with_associations.course_subjects.count).to eq(1)
      end

      it "includes correct course_subject object" do
        expect(subject_with_associations.course_subjects).to include(course_subject)
      end

      it "returns course_subjects with correct type" do
        subject_with_associations.course_subjects.each do |course_subject|
          expect(course_subject).to be_a(CourseSubject)
        end
      end
    end

    describe "courses association" do
      let!(:course1) { create(:course) }
      let!(:course2) { create(:course) }
      let!(:course_subject1) { create(:course_subject, subject: subject_with_associations, course: course1) }
      let!(:course_subject2) { create(:course_subject, subject: subject_with_associations, course: course2) }

      it "has correct number of courses" do
        expect(subject_with_associations.courses.count).to eq(2)
      end

      it "includes correct course objects" do
        expect(subject_with_associations.courses).to include(course1, course2)
      end

      it "returns courses with correct type" do
        subject_with_associations.courses.each do |course|
          expect(course).to be_a(Course)
        end
      end
    end

    describe "user_subjects association" do
      let!(:user) { create(:user, :trainee) }
      let!(:course) { create(:course) }
      let!(:course_subject) { create(:course_subject, subject: subject_with_associations, course: course) }
      let!(:user_course) { create(:user_course, user: user, course: course) }
      let!(:user_subject) { create(:user_subject, user: user, user_course: user_course, course_subject: course_subject) }

      it "has correct number of user_subjects" do
        expect(subject_with_associations.user_subjects.count).to eq(1)
      end

      it "includes correct user_subject object" do
        expect(subject_with_associations.user_subjects).to include(user_subject)
      end

      it "returns user_subjects with correct type" do
        subject_with_associations.user_subjects.each do |user_subject|
          expect(user_subject).to be_a(UserSubject)
        end
      end
    end

    describe "users association" do
      let!(:user1) { create(:user, :trainee) }
      let!(:user2) { create(:user, :trainee) }
      let!(:course) { create(:course) }
      let!(:course_subject) { create(:course_subject, subject: subject_with_associations, course: course) }
      let!(:user_course1) { create(:user_course, user: user1, course: course) }
      let!(:user_course2) { create(:user_course, user: user2, course: course) }
      let!(:user_subject1) { create(:user_subject, user: user1, user_course: user_course1, course_subject: course_subject) }
      let!(:user_subject2) { create(:user_subject, user: user2, user_course: user_course2, course_subject: course_subject) }

      it "has correct number of users" do
        expect(subject_with_associations.users.count).to eq(2)
      end

      it "includes correct user objects" do
        expect(subject_with_associations.users).to include(user1, user2)
      end

      it "returns users with correct type" do
        subject_with_associations.users.each do |user|
          expect(user).to be_a(User)
        end
      end
    end

    describe "nested associations" do
      let!(:course) { create(:course) }
      let!(:course_subject) { create(:course_subject, subject: subject_with_associations, course: course) }
      let!(:user) { create(:user, :trainee) }
      let!(:user_course) { create(:user_course, user: user, course: course) }
      let!(:user_subject) { create(:user_subject, user: user, user_course: user_course, course_subject: course_subject) }
      let!(:user_task) { create(:user_task, user: user, task: task1, user_subject: user_subject) }

      it "can access user_tasks through nested associations" do
        expect(subject_with_associations.users.first.user_tasks).to include(user_task)
      end

      it "can access tasks through user_subjects" do
        expect(subject_with_associations.user_subjects.first.tasks).to include(task1)
      end

      it "can access course through course_subjects" do
        expect(subject_with_associations.course_subjects.first.course).to eq(course)
      end

      it "can access subject through subject_categories" do
        expect(subject_with_associations.subject_categories.first.subject).to eq(subject_with_associations)
      end
    end
  end
end
