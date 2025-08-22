require 'rails_helper'

RSpec.configure do |config|
  config.before(:suite) do
    I18n.default_locale = :en
  end
  config.before(:each) do
    I18n.locale = :en
  end
end
RSpec.describe UserTask, type: :model do
  describe "enums" do
    it "defines status enum with correct values" do
      expect(UserTask.statuses).to eq({
        "not_done" => Settings.user_task.status.not_done,
        "done" => Settings.user_task.status.done
      })
    end

    it "sets default status to not_done" do
      user_task = FactoryBot.create(:user_task)
      expect(user_task.status).to eq("not_done")
    end

    it "allows setting status to done" do
      user_task = FactoryBot.create(:user_task, status: "done")
      expect(user_task.status).to eq("done")
    end
  end

  describe "associations" do
    it "belongs to user" do
      user_task = FactoryBot.create(:user_task)
      expect(user_task.user).to be_a(User)
    end

    it "belongs to task" do
      user_task = FactoryBot.create(:user_task)
      expect(user_task.task).to be_a(Task)
    end

    it "belongs to user_subject" do
      user_task = FactoryBot.create(:user_task)
      expect(user_task.user_subject).to be_a(UserSubject)
    end

    it "has many attached documents" do
      user_task = FactoryBot.create(:user_task)
      expect(user_task.documents).to be_an(ActiveStorage::Attached::Many)
    end
  end

  describe "validations" do

    let!(:user) { FactoryBot.create(:user) }
    let!(:task) { FactoryBot.create(:task) }
    let!(:user_subject) { FactoryBot.create(:user_subject) }
    let!(:original) { FactoryBot.create(:user_task, user: user, task: task, user_subject: user_subject) }

    context "uniqueness of user_id scoped to task_id" do
      it "is not valid when duplicated" do
        duplicate = FactoryBot.build(:user_task, user: user, task: task, user_subject: user_subject)
        duplicate.valid?
        expect(duplicate.errors[:user_id]).to include(I18n.t("activerecord.errors.models.user_task.attributes.user_id.taken"))
      end

      it "is valid with different task" do
        new_task = FactoryBot.create(:task)
        new_record = FactoryBot.build(:user_task, user: user, task: new_task, user_subject: user_subject)
        expect(new_record).to be_valid
      end

      it "is valid with different user" do
        new_user = FactoryBot.create(:user)
        new_record = FactoryBot.build(:user_task, user: new_user, task: task, user_subject: user_subject)
        expect(new_record).to be_valid
      end
    end

    context "spent_time validations" do
      it "is valid with nil spent_time" do
        user_task = FactoryBot.build(:user_task, spent_time: nil)
        expect(user_task).to be_valid
      end

      it "is valid with spent_time greater than or equal to minimum" do
        user_task = FactoryBot.build(:user_task)
        expect(user_task).to be_valid
      end

      it "is invalid with spent_time less than minimum" do
        user_task = FactoryBot.build(:user_task, :invalid_spent_time)
        user_task.valid?
        expect(user_task.errors[:spent_time]).to include(I18n.t("activerecord.errors.models.user_task.attributes.spent_time.greater_than_or_equal_to", count: Settings.user_task.min_spent_time))
      end
    end

    context "documents validations" do
      context "when attaching documents" do
        it "is valid with allowed document types" do
          user_task = FactoryBot.build(:user_task, :with_max_size_documents)
          expect(user_task).to be_valid
        end

        it "is invalid with disallowed document types" do
          user_task = FactoryBot.build(:user_task, :with_invalid_documents)
          user_task.valid?
          expect(user_task.errors[:documents]).to include(
            I18n.t(
              "activerecord.errors.models.user_task.attributes.documents.invalid_document_type"
            )
          )
        end
      end

      context "when checking document size" do
        it "is invalid with document size less than maximum" do
          user_task = FactoryBot.build(:user_task, :with_less_size_documents)
          user_task.valid?
          expect(user_task.errors[:documents]).to include(
            I18n.t(
              "activerecord.errors.models.user_task.attributes.documents.document_size_exceeded"
            )
          )
        end

        it "is valid with document size greater than maximum" do
          user_task = FactoryBot.build(:user_task, :with_large_documents)
          expect(user_task).to be_valid
        end

        it "is valid with document size equal to maximum" do
          user_task = FactoryBot.build(:user_task, :with_max_size_documents)
          expect(user_task).to be_valid
        end
      end

      context "when no documents attached" do
        it "is valid without any documents" do
          user_task = FactoryBot.build(:user_task, documents: [])
          expect(user_task).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    before { UserTask.delete_all }

    let!(:user) { FactoryBot.create(:user) }
    let!(:task) { FactoryBot.create(:task) }
    let!(:user_subject) { FactoryBot.create(:user_subject) }
    let!(:user_task1) { FactoryBot.create(:user_task, user: user, task: task, user_subject: user_subject, status: :not_done, created_at: 2.days.ago) }
    let!(:user_task2) { FactoryBot.create(:user_task, user: user, task: FactoryBot.create(:task), user_subject: user_subject, status: :done, created_at: 1.day.ago) }
    let!(:user_task3) { FactoryBot.create(:user_task, user: FactoryBot.create(:user), task: task, user_subject: FactoryBot.create(:user_subject), status: :not_done) }

    describe ".by_user" do
      it "returns tasks for a specific user" do
        expect(UserTask.by_user(user)).to match_array([user_task1, user_task2])
      end
    end

    describe ".by_task" do
      it "returns tasks for a specific task" do
        expect(UserTask.by_task(task)).to match_array([user_task1, user_task3])
      end
    end

    describe ".tasks_done" do
      it "returns only done tasks" do
        expect(UserTask.tasks_done).to match_array([user_task2])
      end
    end

    describe ".by_user_subject" do
      it "returns tasks for a specific user subject" do
        expect(UserTask.by_user_subject(user_subject)).to match_array([user_task1, user_task2])
      end
    end

    describe ".recent" do
      it "returns user_tasks ordered by created_at descending" do
        expect(UserTask.where(id: [user_task1.id, user_task2.id]).recent).to eq([user_task2, user_task1])
      end
    end

    describe ".not_done" do
      it "returns tasks that are not done" do
        expect(UserTask.not_done).to match_array([user_task1, user_task3])
      end
    end

    describe ".with_deleted" do
      it "returns all user tasks including deleted ones" do
        user_task1.destroy
        expect(UserTask.with_deleted.map(&:id)).to include(user_task2.id, user_task3.id)
      end
    end
  end
end
