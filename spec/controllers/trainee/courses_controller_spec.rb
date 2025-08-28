require "rails_helper"

RSpec.describe Trainee::CoursesController, type: :controller do
  let(:trainee) {create(:user, :trainee)}
  let(:course) do
    create(:course, start_date: 1.week.ago,
           finish_date: 1.week.from_now)
  end
  let!(:user_course) {create(:user_course, user: trainee, course: course)}

  before do
    sign_in trainee
  end

  describe "GET #show" do
    before {get :show, params: {id: course.id}}

    context "when course exists" do
      it "redirects to the subjects page" do
        expect(response).to redirect_to(subjects_trainee_course_path(course))
      end
    end

    context "when course does not exist" do
      before {get :show, params: {id: -1}}

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("trainee.courses.course_not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #members" do
    let!(:other_trainee) {create(:user, :trainee)}
    let!(:other_user_course) do
      create(:user_course, user: other_trainee,
             course: course)
    end
    let!(:supervisor) {create(:user, :supervisor)}
    let!(:course_supervisor) do
      create(:course_supervisor, user: supervisor,
             course: course)
    end

    context "when course exists and has members" do
      before do
        allow(controller).to receive(:pagy).and_return([
          double("pagy",
                count: 2), [trainee, other_trainee]
        ])
        get :members, params: {id: course.id}
      end
      it "assigns trainers" do
        expect(assigns(:trainers)).to include(supervisor)
      end

      it "assigns trainees" do
        expect(assigns(:trainees)).to match_array([trainee, other_trainee])
      end

      it "assigns the correct trainee count" do
        expect(assigns(:trainee_count)).to eq(2)
      end

      it "assigns the correct trainer count" do
        expect(assigns(:trainer_count)).to eq(1)
      end

      it "assigns the correct subject count" do
        expect(assigns(:subject_count)).to eq(course.subjects.count)
      end

      it "renders the members template" do
        expect(response).to render_template(:members)
      end
    end

    context "with valid pagination params" do
      let(:per_page) {Settings.ui.items_per_page}
      let(:page) {2}
      let!(:extra_trainees) do
        create_list(:user, 25, :trainee).each do |t|
          create(:user_course, user: t, course: course)
        end
      end

      before do
        get :members, params: {id: course.id, page: page}
      end

      it "assigns the correct number of trainees per page" do
        expect(assigns(:trainees).size).to eq(per_page)
      end

      it "assigns the correct page of trainees" do
        expected_ids = course.user_courses.trainees.order(:id).limit(per_page).offset((page - 1) * per_page).pluck(:id)
        actual_ids = assigns(:trainees).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end
    end
  end

  describe "GET #subjects" do
    let!(:course_subject1) {create(:course_subject, course: course)}
    let!(:course_subject2) {create(:course_subject, course: course)}
    let!(:subject1) {course_subject1.subject}
    let!(:subject2) {course_subject2.subject}
    let!(:user_subject1) do
      create(:user_subject, user: trainee,
             course_subject: course_subject1)
    end

    before {get :subjects, params: {id: course.id}}

    context "when course exists" do
      it "assigns course subjects" do
        expect(assigns(:course_subjects)).to match_array([course_subject1,
               course_subject2])
      end

      it "assigns the correct subject count" do
        expect(assigns(:subject_count)).to eq(2)
      end

      it "assigns the correct trainee count" do
        expect(assigns(:trainee_count)).to eq(course.trainee_count)
      end

      it "assigns user subjects for the current course" do
        expect(assigns(:user_subjects_for_current_course)).to match_array([user_subject1])
      end

      it "renders the subjects template" do
        expect(response).to render_template(:subjects)
      end
    end
  end
end
