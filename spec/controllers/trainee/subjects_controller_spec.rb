require "rails_helper"

RSpec.describe Trainee::SubjectsController, type: :controller do
  let(:trainee) {create(:user, :trainee)}
  let(:course) do
    create(:course, start_date: 1.week.ago,
           finish_date: 1.week.from_now)
  end
  let(:subject) {create(:subject)}
  let!(:user_course) {create(:user_course, user: trainee, course: course)}
  let!(:course_subject) do
    create(:course_subject, course: course,
           subject: subject)
  end

  before do
    sign_in trainee
  end

  describe "GET #show" do
    let!(:task1) do
      create(:task, :with_course_subject, taskable: course_subject)
    end

    context "when all resources exist and user is enrolled" do
      let!(:user_subject) do
        create(:user_subject, user_course: user_course,
               course_subject: course_subject)
      end
      let!(:comment) do
        create(:comment, user: trainee,
               commentable: user_subject)
      end

      before {get :show, params: {course_id: course.id, id: subject.id}}

      it "assigns the course" do
        expect(assigns(:course)).to eq(course)
      end

      it "assigns the subject" do
        expect(assigns(:subject)).to eq(subject)
      end

      it "assigns the course_subject" do
        expect(assigns(:course_subject)).to eq(course_subject)
      end

      it "assigns the tasks" do
        expect(assigns(:tasks)).to match_array([task1])
      end

      it "assigns the comments" do
        expect(assigns(:comments)).to match_array([comment])
      end

      it "renders the show template" do
        expect(response).to render_template(:show)
      end
    end

    context "when course does not exist" do
      before {get :show, params: {course_id: -1, id: subject.id}}

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.course_not_found"))
      end

      it "redirects to the courses path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when subject does not exist" do
      before {get :show, params: {course_id: course.id, id: -1}}

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.subject_not_found"))
      end

      it "redirects to the course path" do
        expect(response).to redirect_to(trainee_course_path(course))
      end
    end

    context "when user enrollment initialization fails" do
      before do
        allow_any_instance_of(ActiveRecord::Base).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        get :show, params: {course_id: course.id, id: subject.id}
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.subjects.cannot_initialize_subject"))
      end

      it "redirects to the courses path" do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when course_subject does not exist" do
      before do
        allow(CourseSubject).to receive(:find_by).and_return(nil)
        get :show, params: {course_id: course.id, id: subject.id}
      end

      it "assigns tasks as empty array" do
        expect(assigns(:tasks)).to eq([])
      end
    end
  end
end
