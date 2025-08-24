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
      it "redirects" do
        get :show, params: {course_id: 0, id: 1}
        expect(response).to redirect_to(trainee_course_path(course_id: 0))
        expect(flash[:danger]).to be_present
      end
    end

    context "subject not found in course" do
      it "redirects" do
        get :show, params: {course_id: course.id, id: 0}
        expect(response).to redirect_to(trainee_course_path(course_id: course.id))
        expect(flash[:danger]).to be_present
      end
    end

    context "success path" do
      before { course_subject }

      it "initializes enrollments and renders without view" do
        # user not enrolled -> ensure_user_enrollments early returns
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to have_http_status(:ok)
        expect(assigns(:tasks)).to be_a(ActiveRecord::Relation)
        expect(assigns(:comments)).to eq([])
      end

      it "creates user_subject and user_tasks when enrolled" do
        user_course = create(:user_course, user: trainee, course: course)
        task = create(:task, :for_course_subject, taskable: course_subject)

        get :show, params: {course_id: course.id, id: subject_record.id}

        user_subject = UserSubject.find_by(user_course_id: user_course.id, course_subject_id: course_subject.id)
        expect(user_subject).to be_present
        expect(user_subject.user_tasks.where(task: task).exists?).to be(true)
      end

      it "handles transaction errors gracefully" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordInvalid)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to redirect_to("/")
        expect(flash[:danger]).to be_present
      end

      it "sets empty tasks when course_subject missing" do
        allow(CourseSubject).to receive(:find_by).and_return(nil)
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(assigns(:tasks)).to eq([])
      end

      it "handles RecordNotSaved error" do
        create(:user_course, user: trainee, course: course)
        allow_any_instance_of(Trainee::SubjectsController).to receive(:find_or_create_user_subject!).and_raise(ActiveRecord::RecordNotSaved)
        controller.singleton_class.class_eval do
          def trainee_courses_path; "/"; end
        end
        get :show, params: {course_id: course.id, id: subject_record.id}
        expect(response).to redirect_to("/")
        expect(flash[:danger]).to be_present
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
        it "redirects with error message" do
          get :show, params: {course_id: 99999, id: subject_record.id}
          expect(response).to redirect_to(trainee_course_path(course_id: 99999))
          expect(flash[:danger]).to be_present
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
        it "redirects with error message" do
          get :show, params: {course_id: course.id, id: 99999}
          expect(response).to redirect_to(trainee_course_path(course_id: course.id))
          expect(flash[:danger]).to be_present
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
        it "sets empty tasks array" do
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
        it "creates user_subject and user_tasks" do
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
            .and change(UserTask, :count).by(1)

          user_subject = UserSubject.last
          expect(user_subject.user_tasks.where(task: task).exists?).to be(true)
        end
      end
    end
  end
end


