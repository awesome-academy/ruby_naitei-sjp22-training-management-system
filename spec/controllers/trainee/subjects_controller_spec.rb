require "rails_helper"

RSpec.describe Trainee::SubjectsController, type: :controller do
  let(:trainee) { create(:user, :trainee) }
  let(:owner) { create(:user, :supervisor) }
  let(:course) { create(:course, user: owner, supervisor_ids: [owner.id]) }
  let(:subject_record) { create(:subject) }
  let(:course_subject) { create(:course_subject, course: course, subject: subject_record) }

  before do
    allow(controller).to receive(:current_user).and_return(trainee)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(I18n).to receive(:t).and_call_original
  end

  describe "GET show" do
    context "course not found" do
      it "redirects to course path" do
        get :show, params: {course_id: 0, id: 1}
        expect(response).to redirect_to(trainee_course_path(course_id: 0))
      end

      it "shows error message with correct I18n key" do
        get :show, params: {course_id: 0, id: 1}
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.course_not_found"))
      end
    end

    context "subject not found in course" do
      it "redirects to course path" do
        get :show, params: {course_id: course.id, id: 0}
        expect(response).to redirect_to(trainee_course_path(course_id: course.id))
      end

      it "shows error message with correct I18n key" do
        get :show, params: {course_id: course.id, id: 0}
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.subject_not_found"))
      end
    end

    context "success path" do
      before { course_subject }

      it "responds with status ok" do
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to have_http_status(:ok)
      end

      it "assigns tasks as ActiveRecord relation" do
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(assigns(:tasks)).to be_a(ActiveRecord::Relation)
      end

      it "assigns empty comments" do
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(assigns(:comments)).to eq([])
      end

      it "creates user_subject when enrolled" do
        user_course = create(:user_course, user: trainee, course: course)
        task = create(:task, :for_course_subject, taskable: course_subject)

        get :show, params: {course_id: course.id, id: subject_record.id}

        user_subject = UserSubject.find_by(user_course_id: user_course.id, course_subject_id: course_subject.id)
        expect(user_subject).to be_present
      end

      it "creates user_tasks when enrolled" do
        user_course = create(:user_course, user: trainee, course: course)
        task = create(:task, :for_course_subject, taskable: course_subject)

        get :show, params: {course_id: course.id, id: subject_record.id}

        user_subject = UserSubject.find_by(user_course_id: user_course.id, course_subject_id: course_subject.id)
        expect(user_subject.user_tasks.where(task: task).exists?).to be(true)
      end

      it "redirects on RecordInvalid error" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordInvalid)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to redirect_to("/")
      end

      it "shows error message on RecordInvalid error with correct I18n key" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordInvalid)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.subject_in_progress_failed"))
      end

      it "sets empty tasks when course_subject missing" do
        allow(CourseSubject).to receive(:find_by).and_return(nil)
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(assigns(:tasks)).to eq([])
      end

      it "redirects on RecordNotSaved error" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordNotSaved)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to redirect_to("/")
      end

      it "shows error message on RecordNotSaved error with correct I18n key" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordNotSaved)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.subject_in_progress_failed"))
      end
    end
  end

  describe "private helpers coverage" do
    it "covers find_or_create_user_subject! block execution" do
      controller.instance_variable_set(:@user_course, double(id: 1))
      controller.instance_variable_set(:@course_subject, double(id: 2))

      user_subjects_ds = double
      allow(trainee).to receive(:user_subjects).and_return(user_subjects_ds)
      allow(user_subjects_ds).to receive(:find_or_create_by!) do |attrs, &blk|
        us = double
        expect(blk).to be_a(Proc)
        allow(us).to receive(:status=)
        blk.call(us)
        us
      end

      controller.send(:find_or_create_user_subject!)
    end

    it "sets user_subject status when created" do
      controller.instance_variable_set(:@user_course, double(id: 1))
      controller.instance_variable_set(:@course_subject, double(id: 2))

      user_subjects_ds = double
      allow(trainee).to receive(:user_subjects).and_return(user_subjects_ds)
      allow(user_subjects_ds).to receive(:find_or_create_by!) do |attrs, &blk|
        us = double
        expect(us).to receive(:status=).with(Settings.user_subject.status.not_started)
        blk.call(us)
        us
      end

      controller.send(:find_or_create_user_subject!)
    end

    it "covers create_missing_user_tasks creation branch" do
      # prepare @course_subject with tasks.find_each yielding one task
      tasks = double
      allow(tasks).to receive(:find_each).and_yield(:task1)
      course_subject_stub = double(tasks: tasks)
      controller.instance_variable_set(:@course_subject, course_subject_stub)

      # prepare @user_subject with user_tasks.exists? => false then create!
      user_tasks = double
      allow(user_tasks).to receive(:exists?).with(task: :task1).and_return(false)
      allow(user_tasks).to receive(:create!).with(user: trainee, task: :task1, status: Settings.user_task.status.not_done)
      user_subject_stub = double(user_tasks: user_tasks)
      controller.instance_variable_set(:@user_subject, user_subject_stub)

      controller.send(:create_missing_user_tasks)
    end

    it "covers create_missing_user_tasks skip branch" do
      # prepare @course_subject with tasks.find_each yielding one task
      tasks = double
      allow(tasks).to receive(:find_each).and_yield(:task1)
      course_subject_stub = double(tasks: tasks)
      controller.instance_variable_set(:@course_subject, course_subject_stub)

      # prepare @user_subject with user_tasks.exists? => true (skip creation)
      user_tasks = double
      allow(user_tasks).to receive(:exists?).with(task: :task1).and_return(true)
      user_subject_stub = double(user_tasks: user_tasks)
      controller.instance_variable_set(:@user_subject, user_subject_stub)

      controller.send(:create_missing_user_tasks)
    end
  end

  describe "private methods" do
    describe "#load_course" do
      context "when course exists" do
        it "loads course successfully" do
          get :show, params: {course_id: course.id, id: subject_record.id}
          expect(assigns(:course)).to eq(course)
        end
      end

      context "when course does not exist" do
        it "redirects to course path" do
          get :show, params: {course_id: 99999, id: subject_record.id}
          expect(response).to redirect_to(trainee_course_path(course_id: 99999))
        end

        it "shows error message with correct I18n key" do
          get :show, params: {course_id: 99999, id: subject_record.id}
          expect(flash[:danger]).to eq(I18n.t("trainee.subjects.course_not_found"))
        end
      end
    end

    describe "#load_subject" do
      context "when subject exists in course" do
        it "loads subject successfully" do
          # Ensure course_subject exists
          course_subject
          get :show, params: {course_id: course.id, id: subject_record.id}
          expect(assigns(:subject)).to eq(subject_record)
        end
      end

      context "when subject does not exist in course" do
        it "redirects to course path" do
          get :show, params: {course_id: course.id, id: 99999}
          expect(response).to redirect_to(trainee_course_path(course_id: course.id))
        end

        it "shows error message with correct I18n key" do
          get :show, params: {course_id: course.id, id: 99999}
          expect(flash[:danger]).to eq(I18n.t("trainee.subjects.subject_not_found"))
        end
      end
    end

    describe "#load_course_subject" do
      it "loads course_subject when it exists" do
        # Ensure course_subject exists
        course_subject
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(assigns(:course_subject)).to eq(course_subject)
      end

      it "sets course_subject to nil when it does not exist" do
        # Create a subject that's not in the course
        other_subject = create(:subject)
        get :show, params: {course_id: course.id, id: other_subject.id}
        expect(assigns(:course_subject)).to be_nil
      end
    end

    describe "#load_tasks" do
      context "when course_subject exists" do
        it "loads tasks with includes" do
          # Ensure course_subject exists
          course_subject
          get :show, params: {course_id: course.id, id: subject_record.id}
          expect(assigns(:tasks)).to be_a(ActiveRecord::Relation)
        end
      end

      context "when course_subject does not exist" do
        it "redirects to course path" do
          # Create a subject that's not in the course
          other_subject = create(:subject)
          get :show, params: {course_id: course.id, id: other_subject.id}
          # Since load_subject will redirect when subject not in course, 
          # we need to test this differently
          expect(response).to redirect_to(trainee_course_path(course_id: course.id))
        end
      end
    end

    describe "#load_comments" do
      context "when user_subject exists" do
        it "loads comments with includes" do
          # Ensure course_subject exists
          course_subject
          # Create user_course and user_subject
          user_course = create(:user_course, user: trainee, course: course)
          
          # Clear any existing UserSubject to avoid uniqueness conflict
          UserSubject.where(user: trainee, course_subject: course_subject).destroy_all
          
          user_subject = create(:user_subject, user: trainee, user_course: user_course, course_subject: course_subject)
          
          get :show, params: {course_id: course.id, id: subject_record.id}
          expect(assigns(:comments)).to eq([])
        end
      end

      context "when user_subject does not exist" do
        it "sets empty comments array" do
          # Ensure course_subject exists
          course_subject
          get :show, params: {course_id: course.id, id: subject_record.id}
          expect(assigns(:comments)).to eq([])
        end
      end
    end

    describe "#ensure_user_enrollments" do
      context "when user is not enrolled" do
        it "does not create user_subject" do
          # Ensure course_subject exists
          course_subject
          expect {
            get :show, params: {course_id: course.id, id: subject_record.id}
          }.not_to change(UserSubject, :count)
        end
      end

      context "when user is enrolled" do
        it "creates user_subject" do
          # Ensure course_subject exists
          course_subject
          # Create user_course first
          user_course = create(:user_course, user: trainee, course: course)
          task = create(:task, :for_course_subject, taskable: course_subject)
          
          # Clear any existing UserSubject to avoid uniqueness conflict
          UserSubject.where(user: trainee, course_subject: course_subject).destroy_all
          
          expect {
            get :show, params: {course_id: course.id, id: subject_record.id}
          }.to change(UserSubject, :count).by(1)
        end

        it "creates user_tasks" do
          # Ensure course_subject exists
          course_subject
          # Create user_course first
          user_course = create(:user_course, user: trainee, course: course)
          task = create(:task, :for_course_subject, taskable: course_subject)
          
          # Clear any existing UserSubject to avoid uniqueness conflict
          UserSubject.where(user: trainee, course_subject: course_subject).destroy_all
          
          expect {
            get :show, params: {course_id: course.id, id: subject_record.id}
          }.to change(UserTask, :count).by(1)
        end

        it "creates user_task for specific task" do
          # Ensure course_subject exists
          course_subject
          # Create user_course first
          user_course = create(:user_course, user: trainee, course: course)
          task = create(:task, :for_course_subject, taskable: course_subject)
          
          # Clear any existing UserSubject to avoid uniqueness conflict
          UserSubject.where(user: trainee, course_subject: course_subject).destroy_all
          
          get :show, params: {course_id: course.id, id: subject_record.id}

          user_subject = UserSubject.last
          expect(user_subject.user_tasks.where(task: task).exists?).to be(true)
        end
      end
    end
  end

  describe "#create" do
    let(:valid_params) { { name: "New Subject", max_score: 100, estimated_time_days: 5 } }
    let(:invalid_params) { { name: "", max_score: -1, estimated_time_days: 0 } }

    context "when valid params" do
      subject(:action) { post :create, params: { subject: valid_params } }

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

      it "creates subject with all correct attributes" do
        action
        created_subject = Subject.last
        expect(created_subject.attributes.slice('name', 'max_score', 'estimated_time_days')).to eq(valid_params.stringify_keys)
      end

      it "increases subject count by 1" do
        expect { action }.to change(Subject, :count).by(1)
      end

      it "redirects to subjects index" do
        action
        expect(response).to redirect_to(trainee_subjects_path)
      end

      it "shows success message" do
        action
        expect(flash[:success]).to be_present
      end
    end

    context "when invalid params" do
      subject(:action) { post :create, params: { subject: invalid_params } }

      it "does not create subject with invalid name" do
        action
        created_subject = Subject.last
        expect(created_subject&.name).not_to eq(invalid_params[:name])
      end

      it "does not create subject with invalid max_score" do
        action
        created_subject = Subject.last
        expect(created_subject&.max_score).not_to eq(invalid_params[:max_score])
      end

      it "does not create subject with invalid estimated_time_days" do
        action
        created_subject = Subject.last
        expect(created_subject&.estimated_time_days).not_to eq(invalid_params[:estimated_time_days])
      end

      it "does not increase subject count" do
        expect { action }.not_to change(Subject, :count)
      end

      it "renders new template" do
        action
        expect(response).to render_template(:new)
      end

      it "shows error message" do
        action
        expect(flash[:danger]).to be_present
      end
    end

    context "with nested attributes" do
      let(:params_with_tasks) do
        {
          subject: valid_params.merge(
            tasks_attributes: [
              { name: "Task 1", description: "Description 1" },
              { name: "Task 2", description: "Description 2" }
            ]
          )
        }
      end

      it "creates subject with correct nested task attributes" do
        post :create, params: params_with_tasks
        created_subject = Subject.last
        expect(created_subject.tasks.first.name).to eq("Task 1")
        expect(created_subject.tasks.first.description).to eq("Description 1")
        expect(created_subject.tasks.second.name).to eq("Task 2")
        expect(created_subject.tasks.second.description).to eq("Description 2")
      end

      it "creates correct number of tasks" do
        expect { post :create, params: params_with_tasks }.to change(Task, :count).by(2)
      end
    end
  end

  describe "#update" do
    let(:subject_to_update) { create(:subject, name: "Old Name", max_score: 50, estimated_time_days: 3) }
    let(:valid_update_params) { { name: "Updated Name", max_score: 150, estimated_time_days: 7 } }
    let(:invalid_update_params) { { name: "", max_score: -1, estimated_time_days: 0 } }

    context "when valid update params" do
      subject(:action) { patch :update, params: { id: subject_to_update.id, subject: valid_update_params } }

      it "updates subject with correct name" do
        action
        subject_to_update.reload
        expect(subject_to_update.name).to eq(valid_update_params[:name])
      end

      it "updates subject with correct max_score" do
        action
        subject_to_update.reload
        expect(subject_to_update.max_score).to eq(valid_update_params[:max_score])
      end

      it "updates subject with correct estimated_time_days" do
        action
        subject_to_update.reload
        expect(subject_to_update.estimated_time_days).to eq(valid_update_params[:estimated_time_days])
      end

      it "updates subject with all correct attributes" do
        action
        subject_to_update.reload
        expect(subject_to_update.attributes.slice('name', 'max_score', 'estimated_time_days')).to eq(valid_update_params.stringify_keys)
      end

      it "does not change subject count" do
        expect { action }.not_to change(Subject, :count)
      end

      it "redirects to subject show" do
        action
        expect(response).to redirect_to(trainee_subject_path(subject_to_update))
      end

      it "shows success message" do
        action
        expect(flash[:success]).to be_present
      end
    end

    context "when invalid update params" do
      subject(:action) { patch :update, params: { id: subject_to_update.id, subject: invalid_update_params } }

      it "does not update subject with invalid name" do
        action
        subject_to_update.reload
        expect(subject_to_update.name).not_to eq(invalid_update_params[:name])
      end

      it "does not update subject with invalid max_score" do
        action
        subject_to_update.reload
        expect(subject_to_update.max_score).not_to eq(invalid_update_params[:max_score])
      end

      it "does not update subject with invalid estimated_time_days" do
        action
        subject_to_update.reload
        expect(subject_to_update.estimated_time_days).not_to eq(invalid_update_params[:estimated_time_days])
      end

      it "maintains original values" do
        original_name = subject_to_update.name
        original_max_score = subject_to_update.max_score
        original_estimated_time_days = subject_to_update.estimated_time_days
        
        action
        subject_to_update.reload
        
        expect(subject_to_update.name).to eq(original_name)
        expect(subject_to_update.max_score).to eq(original_max_score)
        expect(subject_to_update.estimated_time_days).to eq(original_estimated_time_days)
      end

      it "renders edit template" do
        action
        expect(response).to render_template(:edit)
      end

      it "shows error message" do
        action
        expect(flash[:danger]).to be_present
      end
    end

    context "with nested attributes update" do
      let!(:task) { create(:task, taskable: subject_to_update, name: "Old Task", description: "Old Description") }
      let(:params_with_task_update) do
        {
          subject: valid_params.merge(
            tasks_attributes: [
              { id: task.id, name: "Updated Task", description: "Updated Description" }
            ]
          )
        }
      end

      it "updates task with correct name" do
        patch :update, params: { id: subject_to_update.id, subject: params_with_task_update }
        task.reload
        expect(task.name).to eq("Updated Task")
      end

      it "updates task with correct description" do
        patch :update, params: { id: subject_to_update.id, subject: params_with_task_update }
        task.reload
        expect(task.description).to eq("Updated Description")
      end

      it "updates task with all correct attributes" do
        patch :update, params: { id: subject_to_update.id, subject: params_with_task_update }
        task.reload
        expect(task.attributes.slice('name', 'description')).to eq({ 'name' => 'Updated Task', 'description' => 'Updated Description' })
      end

      it "does not change task count" do
        expect { patch :update, params: { id: subject_to_update.id, subject: params_with_task_update } }.not_to change(Task, :count)
      end
    end
  end

  describe "associations" do
    let(:subject_with_associations) { create(:subject) }
    let(:course_with_associations) { create(:course, user: owner, supervisor_ids: [owner.id]) }
    let!(:course_subject_assoc) { create(:course_subject, course: course_with_associations, subject: subject_with_associations) }
    let!(:task1) { create(:task, :for_course_subject, taskable: course_subject_assoc) }
    let!(:task2) { create(:task, :for_course_subject, taskable: course_subject_assoc) }
    let!(:user_course_assoc) { create(:user_course, user: trainee, course: course_with_associations) }
    let!(:user_subject_assoc) { create(:user_subject, user: trainee, user_course: user_course_assoc, course_subject: course_subject_assoc) }
    let!(:user_task1) { create(:user_task, user: trainee, task: task1, user_subject: user_subject_assoc) }
    let!(:user_task2) { create(:user_task, user: trainee, task: task2, user_subject: user_subject_assoc) }

    describe "course association" do
      it "can access course through course_subject" do
        expect(course_subject_assoc.course).to eq(course_with_associations)
      end

      it "returns course with correct type" do
        expect(course_subject_assoc.course).to be_a(Course)
      end

      it "has correct course user" do
        expect(course_subject_assoc.course.user).to eq(owner)
      end

      it "has correct course supervisor_ids" do
        expect(course_subject_assoc.course.supervisor_ids).to include(owner.id)
      end
    end

    describe "subject association" do
      it "can access subject through course_subject" do
        expect(course_subject_assoc.subject).to eq(subject_with_associations)
      end

      it "returns subject with correct type" do
        expect(course_subject_assoc.subject).to be_a(Subject)
      end
    end

    describe "tasks association through course_subject" do
      it "has correct number of tasks" do
        expect(course_subject_assoc.tasks.count).to eq(2)
      end

      it "includes correct task objects" do
        expect(course_subject_assoc.tasks).to include(task1, task2)
      end

      it "returns tasks with correct type" do
        course_subject_assoc.tasks.each do |task|
          expect(task).to be_a(Task)
        end
      end

      it "tasks belong to correct course_subject" do
        course_subject_assoc.tasks.each do |task|
          expect(task.taskable).to eq(course_subject_assoc)
        end
      end
    end

    describe "user_subject association" do
      it "can access user through user_subject" do
        expect(user_subject_assoc.user).to eq(trainee)
      end

      it "can access user_course through user_subject" do
        expect(user_subject_assoc.user_course).to eq(user_course_assoc)
      end

      it "can access course_subject through user_subject" do
        expect(user_subject_assoc.course_subject).to eq(course_subject_assoc)
      end

      it "returns user_subject with correct type" do
        expect(user_subject_assoc).to be_a(UserSubject)
      end
    end

    describe "user_tasks association through user_subject" do
      it "has correct number of user_tasks" do
        expect(user_subject_assoc.user_tasks.count).to eq(2)
      end

      it "includes correct user_task objects" do
        expect(user_subject_assoc.user_tasks).to include(user_task1, user_task2)
      end

      it "returns user_tasks with correct type" do
        user_subject_assoc.user_tasks.each do |user_task|
          expect(user_task).to be_a(UserTask)
        end
      end

      it "user_task1 belongs to correct user" do
        expect(user_task1.user).to eq(trainee)
      end

      it "user_task1 belongs to correct task" do
        expect(user_task1.task).to eq(task1)
      end

      it "user_task2 belongs to correct user" do
        expect(user_task2.user).to eq(trainee)
      end

      it "user_task2 belongs to correct task" do
        expect(user_task2.task).to eq(task2)
      end
    end

    describe "nested associations" do
      it "can access tasks through user_subject" do
        expect(user_subject_assoc.tasks).to include(task1, task2)
      end

      it "can access course through user_subject" do
        expect(user_subject_assoc.course).to eq(course_with_associations)
      end

      it "can access subject through user_subject" do
        expect(user_subject_assoc.subject).to eq(subject_with_associations)
      end

      it "can access user through user_subject" do
        expect(user_subject_assoc.user).to eq(trainee)
      end

      it "can access user_course through user_subject" do
        expect(user_subject_assoc.user_course).to eq(user_course_assoc)
      end
    end

    describe "user_course association" do
      it "can access user through user_course" do
        expect(user_course_assoc.user).to eq(trainee)
      end

      it "can access course through user_course" do
        expect(user_course_assoc.course).to eq(course_with_associations)
      end

      it "returns user_course with correct type" do
        expect(user_course_assoc).to be_a(UserCourse)
      end
    end

    describe "comments association" do
      let!(:comment1) { create(:comment, user: trainee, commentable: user_subject_assoc) }
      let!(:comment2) { create(:comment, user: owner, commentable: user_subject_assoc) }

      it "has correct number of comments" do
        expect(user_subject_assoc.comments.count).to eq(2)
      end

      it "includes correct comment objects" do
        expect(user_subject_assoc.comments).to include(comment1, comment2)
      end

      it "returns comments with correct type" do
        user_subject_assoc.comments.each do |comment|
          expect(comment).to be_a(Comment)
        end
      end

      it "comments belong to correct commentable" do
        user_subject_assoc.comments.each do |comment|
          expect(comment.commentable).to eq(user_subject_assoc)
        end
      end
    end
  end
end
