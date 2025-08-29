require "rails_helper"

RSpec.describe Trainee::CoursesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:trainee) { create(:user, :trainee) }
  let(:course) { create(:course) }
  let!(:user_course) { create(:user_course, user: trainee, course: course) }

  before do
    sign_in trainee
  end

  describe "GET #show" do
    context "when the course exists" do
      it "redirects to the subjects page for the course" do
        get :show, params: { id: course.id, locale: :vi }
        expect(response).to redirect_to(subjects_trainee_course_path(course, locale: :vi))
      end
    end

    context "when the course does not exist" do
      before { get :show, params: { id: -1, locale: :vi } }

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path(locale: :vi))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.courses.course_not_found"))
      end
    end
  end

  describe "GET #members" do
    context "when the course exists" do

      let!(:supervisor1) { create(:user, :supervisor) }
      let!(:supervisor2) { create(:user, :supervisor) }
      let!(:other_trainees) { create_list(:user, 3, :trainee) }

      before do
        create(:user_course, user: supervisor1, course: course)
        create(:user_course, user: supervisor2, course: course)
        other_trainees.each { |t| create(:user_course, user: t, course: course) }
        
        get :members, params: { id: course.id, locale: :vi }
      end

      it "assigns the course's supervisors to @trainers" do
        expect(assigns(:trainers)).to match_array([supervisor1, supervisor2])
      end

      it "assigns the paginated trainees to @trainees" do
        expect(assigns(:trainees).count).to eq(4) 
      end

      it "assigns the correct trainee count to @trainee_count" do
        expect(assigns(:trainee_count)).to eq(4)
      end

      it "assigns the correct trainer count to @trainer_count" do
        expect(assigns(:trainer_count)).to eq(2)
      end

      it "assigns the correct subject count to @subject_count" do
        expect(assigns(:subject_count)).to eq(course.subjects.count)
      end
    end

    context "when the course does not exist" do
      before { get :members, params: { id: -1, locale: :vi } }

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path(locale: :vi))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.courses.course_not_found"))
      end
    end
  end

  describe "GET #subjects" do
    context "when the course exists" do
      let!(:course_subjects) { create_list(:course_subject, 3, course: course) }

      before do
        # FIX: Create the UserSubject records that link the logged-in trainee
        # to the course's subjects. This was the missing step.
        course_subjects.each do |cs|
          create(:user_subject, user: trainee, course_subject: cs, user_course: user_course)
        end
        
        get :subjects, params: { id: course.id, locale: :vi }
      end

      it "assigns the course's subjects to @course_subjects" do
        expect(assigns(:course_subjects)).to match_array(course_subjects)
      end

      it "assigns the correct subject count to @subject_count" do
        expect(assigns(:subject_count)).to eq(3)
      end

      it "assigns the correct trainee count to @trainee_count" do
        expect(assigns(:trainee_count)).to eq(course.trainee_count)
      end

      it "assigns user's subjects for the course to @user_subjects_for_current_course" do
        expect(assigns(:user_subjects_for_current_course)).to be_present
        expect(assigns(:user_subjects_for_current_course).count).to eq(3)
      end
    end

    context "when the course does not exist" do
      before { get :subjects, params: { id: -1, locale: :vi } }

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path(locale: :vi))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.courses.course_not_found"))
      end
    end
  end

  describe "before_action callbacks" do
    it "#set_courses_page_class sets the correct page class" do
      expect_any_instance_of(Trainee::CoursesController).to receive(:page_class=).with(Settings.page_classes.courses)
      get :show, params: { id: course.id, locale: :vi }
    end
  end
end
