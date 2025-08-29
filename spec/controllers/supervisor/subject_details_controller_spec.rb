require "rails_helper"

RSpec.describe Supervisor::SubjectDetailsController, type: :controller do
  let(:supervisor) {create(:user, :supervisor)}
  let(:course) {create(:course)}
  let(:subject) {create(:subject)}
  let(:course_subject) {create(:course_subject, course: course,
                               subject: subject)
  }
  let!(:user_subject) {create(:user_subject, course_subject: course_subject,
                              user: create(:user, :trainee))
  }
  let!(:task) {create(:task, :with_course_subject, taskable: course_subject)}
  let!(:comment) {create(:comment, user: supervisor,
                         commentable: user_subject)
  }

  before {sign_in supervisor}

  describe "GET #show" do
    context "when course_subject exists" do
      before {get :show, params: {course_id: course.id, id: subject.id}}

      it {expect(response).to have_http_status(:ok)}
      it {expect(assigns(:course_subject)).to eq(course_subject)}
      it {expect(assigns(:subject)).to eq(subject)}
      it {expect(assigns(:subject_tasks)).to include(task)}
      it {expect(assigns(:user_subjects)).to include(user_subject)}
      it {expect(assigns(:user_subject)).to eq(user_subject)}
    end

    context "when course_subject not found" do
      before {get :show, params: {course_id: -1, id: subject.id}}

      it {expect(response).to redirect_to(supervisor_courses_path)}
      it {expect(flash[:danger]).to be_present}
    end

    context "when subject not found" do
      before do
        course_subject.update(subject_id: -1)
        get :show, params: {course_id: course.id, id: -1}
      end

      it {expect(response).to redirect_to(supervisor_courses_path)}
      it {expect(flash[:danger]).to be_present}
    end

    context "when subject is nil in load_subject" do
      before do
        allow_any_instance_of(CourseSubject).to receive(:subject).and_return(nil)
        get :show, params: {course_id: course.id, id: subject.id}
      end

      it {expect(response).to redirect_to(supervisor_courses_path)}
      it {expect(flash[:danger]).to eq(I18n.t("supervisor.subject_details.subject.not_found"))}
    end
  end

  describe "POST #create_task" do
    context "with valid params" do
      it "creates a task" do
        expect {
          post :create_task,
               params: {course_id: course.id, id: subject.id,
                        task: {name: "New Task"}}
        }.to change(Task, :count).by(1)
      end

      context "when a new task is created successfully" do
        before do
          post :create_task, params: {
            course_id: course.id,
            id: subject.id,
            task: {name: "New Task"}
          }
        end

        it "redirects to the subject detail page" do
          expect(response).to redirect_to(supervisor_course_subject_detail_path(
                                            course, subject))
        end

        it "sets a success flash message" do
          expect(flash[:success]).to be_present
        end
      end
    end

    context "with invalid params" do
      it "does not create a new task" do
        expect {
          post :create_task,
              params: {course_id: course.id, id: subject.id,
                       task: {name: ""}}
        }.not_to change(Task, :count)
      end

      it "redirects to subject detail" do
        post :create_task,
             params: {course_id: course.id, id: subject.id, task: {name: ""}}
        expect(response).to redirect_to(supervisor_course_subject_detail_path(
                                          course, subject))
      end
    end

    context "when a StandardError is raised" do
      before do
        allow_any_instance_of(CourseSubject).to receive_message_chain(:tasks,
                                                                      :build).and_raise(StandardError)
      end

      it "does not create the task" do
        expect {
          post :create_task,
                params: {course_id: course.id, id: subject.id,
                        task: {name: "New Task"}}
        }.not_to change(Task, :count)
      end

      it "sets danger flash" do
        post :create_task,
             params: {course_id: course.id, id: subject.id,
                      task: {name: "New Task"}}
        expect(flash[:danger]).to be_present
      end
    end
  end

  describe "PATCH #update_task" do
    context "when task is found" do
      before do
        patch :update_task, params: {
          course_id: course.id,
          id: subject.id,
          task_id: task.id,
          task: {name: "Updated"}
        }
      end

      it "updates the task name successfully" do
        expect(task.reload.name).to eq("Updated")
      end

      it "sets a success flash message" do
        expect(flash[:success]).to be_present
      end
    end

    context "when task not found" do
      before do
        patch :update_task, params: {
          course_id: course.id,
          id: subject.id,
          task_id: -1,
          task: {name: "Updated"}
        }
      end

      it "redirects to supervisor_courses_path" do
        expect(response).to redirect_to(supervisor_courses_path)
      end

      it "sets danger flash" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(Task).to receive(:update).and_return(false)
        patch :update_task,
              params: {course_id: course.id, id: subject.id, task_id: task.id,
                       task: {name: "Updated"}}
      end

      it {expect(flash[:danger]).to be_present}
      it {expect(response).to have_http_status(:found)}
    end
  end

  describe "PATCH #update_score" do
    
    context "when the score is successfully updated" do
      before do
        patch :update_score, params: {
          course_id: course.id,
          id: subject.id,
          user_id: user_subject.user.id,
          score: 20
        }
      end

      it "updates the user's score for the subject" do
        expect(user_subject.reload.score).to eq(20)
      end

      it "sets a success flash message" do
        expect(flash[:success]).to be_present
      end
    end

    context "when user_subject not found" do
      context "with invalid user_id param" do
        before do
          patch :update_score,
                params: {course_id: course.id, id: subject.id, user_id: -1,
                         score: 99}
        end

        it {expect(response).to redirect_to(supervisor_course_subject_detail_path(course, subject))
        }
        it {expect(flash[:danger]).to be_present}
      end

      context "with nil user_id and mocked query returns none" do
        before do
          patch :update_score,
                params: {course_id: course.id, id: subject.id, user_id: nil,
                         score: 99}
        end

        it {expect(response).to redirect_to(supervisor_course_subject_detail_path(course,
                                                                                subject))
        }
        it {expect(flash[:danger]).to eq(I18n.t("supervisor.subject_details.update_score.update_failed"))
        }
      end
    end
    
  end

  describe "POST #create_comment" do
    it "creates comment" do
      expect {
        post :create_comment,
                           params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                                    comment: {content: "Hello"}}
      }.to change(Comment, :count).by(1)
    end

    it "sets success flash" do
      post :create_comment,
           params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                    comment: {content: "Hello"}}
      expect(flash[:success]).to be_present
    end

    it "fails with invalid content" do
      post :create_comment,
           params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                    comment: {content: ""}}
      expect(flash[:danger]).to be_present
    end
  end

  describe "PATCH #update_comment" do
    context "when the comment is successfully updated" do
      let(:updated_content) {"Updated"}

      before do
        patch :update_comment, params: {
          course_id: course.id,
          id: subject.id,
          user_id: user_subject.user.id,
          comment_id: comment.id,
          comment: {content: updated_content}
        }
      end

      it "updates the comment content" do
        expect(comment.reload.content).to eq(updated_content)
      end

      it "sets a success flash message" do
        expect(flash[:success]).to be_present
      end
    end

    context "when the comment is not found" do
      before do
        patch :update_comment, params: {
          course_id: course.id,
          id: subject.id,
          user_id: user_subject.user.id,
          comment_id: -1,
          comment: {content: "Updated"}
        }
      end

      it "redirects to the subject detail page" do
        expect(response).to redirect_to(supervisor_course_subject_detail_path(
                                          course, subject))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(Comment).to receive(:update).and_return(false)
        patch :update_comment,
              params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                       comment_id: comment.id, comment: {content: "Updated"}}
      end

      it {expect(flash[:danger]).to be_present}
      it {expect(comment.reload.content).not_to eq("Updated")}
    end
  end

  describe "DELETE #destroy_comment" do
    context "when comment is successfully deleted" do
      before do
        delete :destroy_comment,
               params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                        comment_id: comment.id}
      end

      it "deletes the comment" do
        expect(Comment.exists?(comment.id)).to be_falsey
      end

      it "sets a success flash message" do
        expect(flash[:success]).to be_present
      end
    end

    context "when comment is not found" do
      before do
        delete :destroy_comment,
               params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                        comment_id: -1}
      end

      it "redirects to the subject detail page" do
        expect(response).to redirect_to(supervisor_course_subject_detail_path(
                                          course, subject))
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to be_present
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Comment).to receive(:destroy).and_return(false)
        delete :destroy_comment,
               params: {course_id: course.id, id: subject.id, user_id: user_subject.user.id,
                        comment_id: comment.id}
      end

      it {expect(Comment.exists?(comment.id)).to be_truthy}
      it {expect(flash[:danger]).to be_present}
    end
  end
end
