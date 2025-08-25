require "rails_helper"

RSpec.describe Trainee::UserTasksController, type: :controller do
  include Rails.application.routes.url_helpers

  around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  let(:unique_suffix) { SecureRandom.hex(4) }
  
  let!(:course)         { FactoryBot.create(:course, name: "Course #{unique_suffix}") }
  let!(:subject)        { FactoryBot.create(:subject) }
  let!(:course_subject) { FactoryBot.create(:course_subject, course: course, subject: subject) }
  let!(:user)           { FactoryBot.create(:user) }
  let!(:task)           { FactoryBot.create(:task) }
  let!(:user_subject)   { FactoryBot.create(:user_subject, course_subject: course_subject, user: user, status: :not_started, started_at: nil) }
  let!(:user_task)      { FactoryBot.create(:user_task, user: user, user_subject: user_subject, task: task, status: :not_done) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  
  end

  describe "PATCH #update_document" do
    context "when document is attached" do
      let(:file) { fixture_file_upload("sample_document_test.pdf", "application/pdf") }

      it "attaches the document and sets success flash" do
        patch :update_document, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          document: file
        }
        user_task.reload
        expect(
          attached: user_task.documents.attached?,
          flash: flash[:success],
          redirect: URI.parse(response.location).path,
        ).to eq(
          attached: true,
          flash: I18n.t("trainee.user_tasks.update_document.document_updated"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end

      it "attaches the document correct data" do
        patch :update_document, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          document: file
        }
        user_task.reload
        new_document = user_task.documents.last
        expect(
          filename: new_document.filename.to_s,
          content_type: new_document.content_type
        ).to eq(
          filename: "sample_document_test.pdf",
          content_type: "application/pdf"
        )
      end
    end

    context "when document is not attached" do
      it "sets danger flash" do
        patch :update_document, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id
        }
        expect(
          flash: flash[:danger],
          redirect: URI.parse(response.location).path
        ).to eq(
          flash: I18n.t("trainee.user_tasks.update_document.document_update_failed"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end

    context "when user_task does not exist and will be created" do
      it "creates new user_task and attaches document" do
        new_user_subject = FactoryBot.create(:user_subject, 
          course_subject: course_subject, 
          user: user, 
          status: :not_started
        )
        new_task = FactoryBot.create(:task)
        
        expect {
          patch :update_document, params: {
            id: 99999,
            task_id: new_task.id,
            user_subject_id: new_user_subject.id,
            document: fixture_file_upload("sample_document_test.pdf", "application/pdf")
          }
        }.to change(UserTask, :count).by(1)
      end

      it "creates new user_task with correct data" do
        new_user_subject = FactoryBot.create(:user_subject, 
          course_subject: course_subject, 
          user: user, 
          status: :not_started
        )
        new_task = FactoryBot.create(:task)
        patch :update_document, params: {
          id: 99999,
          task_id: new_task.id,
          user_subject_id: new_user_subject.id,
          document: fixture_file_upload("sample_document_test.pdf", "application/pdf")
        }
        new_user_task = UserTask.last
        expect(
          user: new_user_task.user,
          user_subject: new_user_task.user_subject,
          task: new_user_task.task
        ).to eq(
          user: user,
          user_subject: new_user_subject,
          task: new_task
        )
      end
    end
  end

  describe "PATCH #update_status" do
    context "with valid status param" do
      it "toggles from not_done to done when param equals Settings value" do
        user_task.update!(status: :not_done)
        patch :update_status, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          status: Settings.user_task.status.done
        }
        user_task.reload
        expect(
          status: user_task.status,
          flash: flash[:success],
          redirect: URI.parse(response.location).path
        ).to eq(
          status: :done.to_s,
          flash: I18n.t("trainee.user_tasks.update_status.status_updated"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
      
      it "toggles from done to not_done when status param is not_done" do
        user_task.update!(status: :done)
        
        patch :update_status, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          status: Settings.user_task.status.not_done
        }
        expect(
          status: user_task.reload.status,
          flash: flash[:success]
        ).to eq(
          status: :not_done.to_s,
          flash: I18n.t("trainee.user_tasks.update_status.status_updated")
        )
      end

      context "when update fails" do
        it "sets danger flash" do
          allow_any_instance_of(UserTask).to receive(:update).and_return(false)
          patch :update_status, params: {
            id: user_task.id,
            task_id: task.id,
            user_subject_id: user_subject.id,
            status: :done
          }
          expect(
            flash: flash[:danger],
            redirect: URI.parse(response.location).path
          ).to eq(
            flash: I18n.t("trainee.user_tasks.update_status.status_update_failed"),
            redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
          )
        end
      end
    end
  end

  describe "PATCH #update_spent_time" do
    context "with present spent_time param" do
      it "updates spent_time and sets success flash" do
        patch :update_spent_time, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          spent_time: 15
        }
        expect(
          spent_time: user_task.reload.spent_time,
          flash: flash[:success],
          redirect: URI.parse(response.location).path
        ).to eq(
          spent_time: 15,
          flash: I18n.t("trainee.user_tasks.update_spent_time.spent_time_updated"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end

    context "when update fails" do
      it "sets danger flash" do
        allow_any_instance_of(UserTask).to receive(:update).and_return(false)
        patch :update_spent_time, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          spent_time: 20
        }
        expect(
          flash: flash[:danger],
          redirect: URI.parse(response.location).path
        ).to eq(
          flash: I18n.t("trainee.user_tasks.update_spent_time.spent_time_update_failed"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end

    context "when spent_time param is blank" do
      it "sets danger flash" do
        patch :update_spent_time, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id
        }
        expect(
          flash: flash[:danger],
          redirect: URI.parse(response.location).path
        ).to eq(
          flash: I18n.t("trainee.user_tasks.update_spent_time.spent_time_update_failed"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end
  end

  describe "DELETE #destroy_document" do
    let!(:attachment) do
      user_task.documents.attach(
        io: StringIO.new("test content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
      user_task.documents.last
    end

    context "with valid document_id" do
      it "purges the document and sets success flash" do
        expect(user_task.documents).to be_attached
        attachment_id = attachment.id
        
        delete :destroy_document, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          document_id: attachment_id
        }
        expect(response).to redirect_to(
          trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end

    context "with invalid document_id" do
      it "sets danger flash" do
        delete :destroy_document, params: {
          id: user_task.id,
          task_id: task.id,
          user_subject_id: user_subject.id,
          document_id: 99999
        }
        expect(
          flash: flash[:danger],
          redirect: URI.parse(response.location).path
        ).to eq(
          flash: I18n.t("trainee.user_tasks.destroy_document.document_not_found"),
          redirect: trainee_course_subject_path(course_id: course.id, id: subject.id, locale: I18n.locale)
        )
      end
    end
  end

  describe "private#make_subject_in_progress" do
    context "when user_subject status is not_started" do
      it "updates to in_progress and sets started_at" do
        controller.instance_variable_set(:@user_task, user_task)
        controller.send(:make_subject_in_progress)
        ut_user_subject = user_task.user_subject.reload
        expect(
          status: ut_user_subject.status,
          started_at: ut_user_subject.started_at.to_date
        ).to eq(
          status: "in_progress",
          started_at: Time.zone.today
        )
      end
    end

    context "when user_subject status is not not_started" do
      it "does not update" do
        user_subject.update!(status: "in_progress")
        controller.instance_variable_set(:@user_task, user_task)
        controller.send(:make_subject_in_progress)
        user_subject.reload
        expect(user_subject.status).to eq("in_progress")
      end
    end

    context "when user_subject update fails" do
      it "returns false when update fails" do
        allow_any_instance_of(UserSubject).to receive(:update).and_return(false)
        controller.instance_variable_set(:@user_task, user_task)
        result = controller.send(:make_subject_in_progress)
        expect(result).to be_falsey
      end
    end

    context "when user_task has no user_subject" do
      it "returns nil" do
        fake_user_task = double(user_subject: nil)
        controller.instance_variable_set(:@user_task, fake_user_task)
        expect(controller.send(:make_subject_in_progress)).to be_nil
      end
    end
  end

  describe "private#handle_invalid_course_or_subject" do
    it "sets danger flash (do not test redirect)" do
      controller.instance_variable_set(:@course_id, course.id)
      controller.send(:handle_invalid_course_or_subject)
      expect(flash[:danger]).to be_present
    end
  end

  describe "private#extract_course_and_subject_id" do
    it "returns [course_id, subject_id]" do
      arr = controller.send(:extract_course_and_subject_id, user_task)
      expect(arr).to eq([course.id, subject.id])
    end

    it "returns [nil, nil] if user_subject is nil" do
      arr = controller.send(:extract_course_and_subject_id, nil)
      expect(arr).to eq([nil, nil])
    end

    it "returns [nil, nil] if user_task.user_subject has nil course_subject" do
      mock_user_subject = double('user_subject', course_subject: nil)
      mock_user_task = double('user_task', user_subject: mock_user_subject)
      
      arr = controller.send(:extract_course_and_subject_id, mock_user_task)
      expect(arr).to eq([nil, nil])
    end
  end

  describe "private methods" do
    describe "private#load_user_task" do
      it "loads or creates user_task and attachments" do
        controller.params = ActionController::Parameters.new(task_id: task.id, user_subject_id: user_subject.id)
        
        expect { controller.send(:load_user_task) }
          .to change { assigns(:user_task) }.to(be_a(UserTask))
      end

      it "creates new user_task if not exists" do
        new_task = FactoryBot.create(:task)
        controller.params = ActionController::Parameters.new(task_id: new_task.id, user_subject_id: user_subject.id)
        
        expect {
          controller.send(:load_user_task)
        }.to change(UserTask, :count).by(1)
      end
    end

    describe "private#load_course_and_subject_id" do
      it "assigns course_id and subject_id if valid" do
        controller.instance_variable_set(:@user_task, user_task)
        controller.send(:load_course_and_subject_id)
        expect(
          course_id: assigns(:course_id),
          subject_id: assigns(:subject_id)
        ).to eq(
          course_id: course.id,
          subject_id: subject.id
        )
      end

      it "calls handle_invalid_course_or_subject if invalid" do
        controller.instance_variable_set(:@user_task, nil)
        expect(controller).to receive(:handle_invalid_course_or_subject)
        controller.send(:load_course_and_subject_id)
      end
    end
  end

  describe "private#safe_redirect_to_course_subject" do
    controller(Trainee::UserTasksController) do
      def test_action
        @course_id = params[:course_id]
        @subject_id = params[:subject_id]
        safe_redirect_to_course_subject
      end
    end

    before do
      routes.draw do
        get "test_action" => "trainee/user_tasks#test_action"
        get "trainee/courses/:course_id/subjects/:id", to: "trainee/course_subjects#show", as: :trainee_course_subject
        get "trainee/courses/:id", to: "trainee/courses#show", as: :trainee_course
        get "trainee/courses", to: "trainee/courses#index", as: :trainee_courses
      end
    end

    it "redirects to course_subject if both ids present" do
      get :test_action, params: {course_id: course.id, subject_id: subject.id}
      expect(response).to redirect_to(trainee_course_subject_path(  course_id: course.id, id: subject.id, locale: I18n.locale))
    end

    it "redirects to course if only course_id present" do
      get :test_action, params: {course_id: course.id}
      expect(response).to redirect_to(trainee_course_path(id: course.id, locale: I18n.locale))
    end

    it "redirects to courses if no ids present" do
      get :test_action
      expect(response).to redirect_to(root_path(locale: I18n.locale))
    end
  end
end
