# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  let(:subject_instance) {create(:subject)}

  describe "validations" do
    it "is valid with valid attributes" do
      task = build(:task, taskable: subject_instance)
      expect(task).to be_valid
    end

    it "is invalid without a name" do
      task = build(:task, name: nil, taskable: subject_instance)
      expect(task).not_to be_valid
    end

    it "is invalid with a too long name" do
      task = build(:task, name: "a" * (Settings.task.max_name_length + 1),
                   taskable: subject_instance)
      expect(task).not_to be_valid
    end

    context "when name is not unique" do
      before {create(:task, name: "UniqueName", taskable: subject_instance)}

      it "is invalid" do
        duplicate = build(:task, name: "UniqueName", taskable: subject_instance)
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe "associations" do
    it "belongs to taskable as polymorphic" do
      association = Task.reflect_on_association(:taskable)
      expect(association.macro).to eq(:belongs_to)
    end

    context "with an associated Subject" do
      let!(:subject) { create(:subject, name: "Math") }
      let!(:task) { create(:task, :with_subject, taskable: subject, name: "Homework 1") }

      it "sets the correct associated taskable record" do
        expect(task.taskable).to eq(subject)
      end

      it "correctly returns the taskable's attributes" do
        expect(task.taskable.name).to eq("Math")
      end

      it "correctly associates the task with the subject" do
        expect(subject.tasks).to include(task)
      end
    end

    context "with a CourseSubject as a taskable" do
      let!(:course_subject) { create(:course_subject) }
      let!(:task) do
        create(:task, :with_course_subject, taskable: course_subject, name: "Course task")
      end

      it "sets the correct taskable" do
        expect(task.taskable).to eq(course_subject)
      end

      it "associates the task with the course subject" do
        expect(course_subject.tasks).to include(task)
      end
    end

    it "taskable is polymorphic" do
      association = Task.reflect_on_association(:taskable)
      expect(association.options[:polymorphic]).to be true
    end

    it "has many user_tasks" do
      association = Task.reflect_on_association(:user_tasks)
      expect(association.macro).to eq(:has_many)
    end

    it "has many users through user_tasks" do
      association = Task.reflect_on_association(:users)
      expect(association.options[:through]).to eq(:user_tasks)
    end
  end

  describe "scopes" do
    let!(:task1) do
      create(:task, name: "Alpha", taskable: subject_instance,
             created_at: 1.day.ago)
    end
    let!(:task2) do
      create(:task, name: "Beta", taskable: subject_instance,
             created_at: Time.current)
    end

    it "orders by name ascending" do
      result = Task.where(id: [task1.id, task2.id]).ordered_by_name.to_a
      expect(result).to eq([task1, task2])
    end

    it "filters by taskable_type" do
      result = Task.for_taskable_type("Subject")
      expect(result).to include(task1, task2)
    end

    it "finds task by name when query matches" do
      result = Task.search_by_name("Alpha")
      expect(result).to include(task1)
    end

    it "does not return unmatched task in search" do
      result = Task.search_by_name("Alpha")
      expect(result).not_to include(task2)
    end

    it "returns all tasks when query is nil" do
      result = Task.search_by_name(nil)
      expect(result).to include(task1, task2)
    end

    it "orders by most recent first" do
      result = Task.recent.first
      expect(result).to eq(task2)
    end

    it "filters by subject id" do
      result = Task.by_subject(subject_instance.id)
      expect(result).to include(task1, task2)
    end

    it "returns all when subject id is nil" do
      result = Task.by_subject(nil)
      expect(result).to include(task1, task2)
    end
  end

  describe "delegates" do
    it "delegates taskable_name to subject name" do
      task = create(:task, taskable: subject_instance)
      expect(task.taskable_name).to eq(subject_instance.name)
    end
  end

  describe "callbacks" do
    context "when taskable_type is not course_subject" do
      it "does not create user_tasks" do
        task = create(:task, taskable: subject_instance)
        expect(task.user_tasks.count).to eq(0)
      end
    end

    context "when taskable_type is course_subject" do
      let(:course_subject) {create(:course_subject)}
      let(:trainee) {create(:user, role: :trainee)}
      let!(:user_subject) do
        create(:user_subject,
               course_subject: course_subject, user: trainee)
      end

      it "creates user_tasks for trainees" do
        task = create(:task, taskable: course_subject,
                      taskable_type: Settings.task.taskable_type.course_subject)
        expect(task.user_tasks.count).to eq(1)
      end

      it "assigns created user_task to the trainee" do
        task = create(:task, taskable: course_subject,
                      taskable_type: Settings.task.taskable_type.course_subject)
        expect(task.user_tasks.first.user).to eq(trainee)
      end
    end
  end
end
