# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supervisor::UserCoursesController, type: :controller do
  let(:supervisor) {create(:user, :supervisor)}
  let(:course) {create(:course, supervisors: [supervisor])}
  let(:trainee1) {create(:user, :trainee)}
  let(:trainee2) {create(:user, :trainee)}

  before do
    sign_in supervisor
  end

  # The `destroy` action handles removing a trainee from a course.
  describe "DELETE #destroy" do
    let!(:user_course) {create(:user_course, user: trainee1, course: course)}

    context "when the user course is successfully destroyed" do
      before do
        allow_any_instance_of(UserCourse).to receive(:destroy).and_return(true)
        request.env["HTTP_REFERER"] = members_supervisor_course_path(course)
        delete :destroy, params: {course_id: course.id, id: user_course.id}
      end

      it "sets a success flash message" do
        expect(flash[:success]).to eq(I18n.t("courses.destroy_user_course.success"))
      end

      it "redirects back to the previous page" do
        expect(response).to redirect_to(members_supervisor_course_path(course))
      end
    end

    context "when the user course fails to be destroyed" do
      before do
        request.env["HTTP_REFERER"] = members_supervisor_course_path(course)
        allow_any_instance_of(UserCourse).to receive(:destroy).and_return(false)
        delete :destroy, params: {course_id: course.id, id: user_course.id}
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("courses.destroy_user_course.failed"))
      end

      it "redirects back to the previous page" do
        expect(response).to redirect_to(members_supervisor_course_path(course))
      end
    end

    context "when the user course is not found" do
      before do
        delete :destroy, params: {course_id: course.id, id: -1}
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("courses.errors.user_course_not_found"))
      end

      it "redirects back to the previous page" do
        expect(response).to redirect_to(members_supervisor_course_path(course))
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        user_ids: [trainee1.id, trainee2.id],
        course_id: course.id
      }
    end

    context "when trainees are successfully added" do
      before do
        post :create, params: valid_params, format: :json
      end

      it "creates a new user course for each trainee" do
        expect(UserCourse.where(user_id: [trainee1.id, trainee2.id],
                                course_id: course.id).count).to eq(2)
      end

      it "returns a JSON response with added count and status :ok" do
        expect(response.content_type).to eq("application/json; charset=utf-8")
        json_response = JSON.parse(response.body)
        expect(json_response["added"]).to eq(2)
        expect(response).to have_http_status(:ok)
      end

      context "when some trainees are already enrolled" do
        before do
          post :create, params: valid_params, format: :json
        end

        it "only creates a new user course for trainees not yet enrolled" do
          expect(UserCourse.where(user_id: trainee2.id,
                                  course_id: course.id).count).to eq(1)
        end

        it "returns a JSON response with the correct added count" do
          json_response = JSON.parse(response.body)
          expect(json_response["added"]).to eq(0)
        end
      end
    end

    context "when a trainee fails to be added" do
      before do
        allow_any_instance_of(UserCourse).to receive(:save).and_return(false)
        post :create, params: valid_params, format: :json
      end

      it "returns a JSON response with an error message and status :unprocessable_entity" do
        expect(response.content_type).to eq("application/json; charset=utf-8")
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq(I18n.t(
            "supervisor.user_courses.create.failed_to_add_trainee", name: trainee1.name
            ))
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create any user courses" do
        expect(UserCourse.count).to eq(0)
      end
    end

    context "when an unexpected error occurs during transaction" do
      before do
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:find_or_initialize_by).and_raise(StandardError)
        post :create, params: valid_params, format: :json
      end

      it "returns a JSON response with an unexpected error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq(I18n.t("supervisor.user_courses.create.unexpected_error"))
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when course is not found" do
      before do
        post :create, params: {course_id: -1, user_ids: [trainee1.id]}
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("courses.errors.course_not_found"))
      end

      it "redirects to the root path" do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
