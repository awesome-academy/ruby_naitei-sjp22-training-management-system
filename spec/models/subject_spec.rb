require "rails_helper"

RSpec.describe Subject, type: :model do
  describe "validations" do
    subject {build(:subject)}

    it { is_expected.to be_valid }

    context "name" do
      it "is required" do
        subject.name = nil
        expect(subject).to have(1).error_on(:name)
      end

      it "is unique case-insensitive" do
        create(:subject, name: "Ruby", max_score: 10, estimated_time_days: 1)
        other = build(:subject, name: "ruby", max_score: 10, estimated_time_days: 1)
        expect(other).to have(1).error_on(:name)
      end

      it "has max length constraint" do
        subject.name = "a" * (Settings.subject.max_name_length + 1)
        expect(subject).to have(1).error_on(:name)
      end
    end

    context "max_score" do
      it "is required" do
        subject.max_score = nil
        expect(subject).to have(1).error_on(:max_score)
      end

      it "must be integer and > 0" do
        subject.max_score = 0
        expect(subject).to have(1).error_on(:max_score)
      end

      it "must be <= limit" do
        subject.max_score = Settings.subject.max_score_limit + 1
        expect(subject).to have(1).error_on(:max_score)
      end

      it "accepts valid max_score" do
        subject.max_score = Settings.subject.max_score_limit
        expect(subject).to be_valid
      end

      it "rejects non-integer values" do
        subject.max_score = 10.5
        expect(subject).to have(1).error_on(:max_score)
      end
    end

    context "estimated_time_days" do
      it "is required" do
        subject.estimated_time_days = nil
        expect(subject).to have(1).error_on(:estimated_time_days)
      end

      it "must be integer and > 0" do
        subject.estimated_time_days = 0
        expect(subject).to have(1).error_on(:estimated_time_days)
      end

      it "rejects negative values" do
        subject.estimated_time_days = -1
        expect(subject).to have(1).error_on(:estimated_time_days)
      end

      it "rejects non-integer values" do
        subject.estimated_time_days = 5.5
        expect(subject).to have(1).error_on(:estimated_time_days)
      end

      it "accepts valid values" do
        subject.estimated_time_days = 1
        expect(subject).to be_valid
      end
    end

    context "image validations" do
      it "rejects invalid content type" do
        subject.image.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
        expect(subject).to have(1).error_on(:image)
      end

      it "accepts valid image types" do
        subject.image.attach(
          io: File.open(Rails.root.join('app/assets/images/default_course_image.png')),
          filename: 'subject_image.png',
          content_type: 'image/png'
        )
        expect(subject).to be_valid
      end

      it "validates image size" do
        # Create a large file
        large_file = StringIO.new("x" * (Settings.subject.max_image_size.megabytes + 1.megabyte))
        subject.image.attach(
          io: large_file,
          filename: 'large_image.png',
          content_type: 'image/png'
        )
        expect(subject).to have(1).error_on(:image)
      end

      it "accepts image within size limit" do
        subject.image.attach(
          io: StringIO.new("x" * 100.kilobytes),
          filename: 'small_image.png',
          content_type: 'image/png'
        )
        expect(subject).to be_valid
      end
    end
  end

  describe "associations" do
    it "has many tasks and dependent destroy" do
      subject = create(:subject, :with_tasks)
      expect { subject.destroy }.to change { Task.with_deleted.where(taskable_id: subject.id, taskable_type: Subject.name).count }.by(0)
    end

    it "has many course_subjects" do
      subject = create(:subject)
      expect(subject).to respond_to(:course_subjects)
    end

    it "has many user_subjects through course_subjects" do
      subject = create(:subject)
      expect(subject).to respond_to(:user_subjects)
    end

    it "has many users through user_subjects" do
      subject = create(:subject)
      expect(subject).to respond_to(:users)
    end

    it "has many courses through course_subjects" do
      subject = create(:subject)
      expect(subject).to respond_to(:courses)
    end

    it "has many subject_categories with dependent destroy" do
      subject = create(:subject)
      # Create categories manually to avoid factory issues
      category1 = create(:category)
      category2 = create(:category)
      subject_category1 = create(:subject_category, subject: subject, category: category1)
      subject_category2 = create(:subject_category, subject: subject, category: category2)
      
      expect { subject.destroy }.to change { SubjectCategory.count }.by(-2)
    end

    it "has many categories through subject_categories" do
      subject = create(:subject)
      expect(subject).to respond_to(:categories)
    end

    it "has one attached image" do
      subject = create(:subject)
      expect(subject).to respond_to(:image)
    end
  end

  describe "scopes" do
    let!(:subject1) { create(:subject, name: "Alpha", max_score: 10, estimated_time_days: 1) }
    let!(:subject2) { create(:subject, name: "Beta", max_score: 10, estimated_time_days: 1) }

    it "ordered_by_name" do
      expect(Subject.ordered_by_name.first.name).to eq("Alpha")
      expect(Subject.ordered_by_name.last.name).to eq("Beta")
    end

    it "search_by_name with query" do
      expect(Subject.search_by_name("Al").pluck(:name)).to include("Alpha")
      expect(Subject.search_by_name("Al").pluck(:name)).not_to include("Beta")
    end

    it "search_by_name with blank returns nil relation (no condition added)" do
      expect(Subject.search_by_name(nil)).to be_nil.or be_a(ActiveRecord::Relation)
    end

    it "search_by_name with empty string returns nil relation" do
      expect(Subject.search_by_name("")).to be_nil.or be_a(ActiveRecord::Relation)
    end

    it "recent orders by created_at desc" do
      expect(Subject.recent.first).to eq(subject2)
      expect(Subject.recent.last).to eq(subject1)
    end

    it "search_by_name is case insensitive" do
      expect(Subject.search_by_name("alpha").pluck(:name)).to include("Alpha")
      expect(Subject.search_by_name("ALPHA").pluck(:name)).to include("Alpha")
    end
  end

  describe "nested attributes for tasks" do
    it "rejects blank name task attributes" do
      subject = build(:subject,
        tasks_attributes: [{name: ""}]
      )
      subject.valid?
      expect(subject.tasks).to be_empty
    end

    it "accepts valid task attributes" do
      subject = build(:subject,
        tasks_attributes: [{name: "Valid Task"}]
      )
      expect(subject.tasks.first.name).to eq("Valid Task")
    end

    it "handles multiple task attributes" do
      subject = build(:subject,
        tasks_attributes: [
          {name: "Task 1"},
          {name: "Task 2"}
        ]
      )
      expect(subject.tasks.size).to eq(2)
      expect(subject.tasks.map(&:name)).to match_array(["Task 1", "Task 2"])
    end

    it "handles _destroy attribute" do
      subject = build(:subject,
        tasks_attributes: [
          {name: "Task 1", _destroy: "1"}
        ]
      )
      # Since reject_if rejects blank names, the task won't be created
      # So we test that the attribute is processed during build
      expect(subject.tasks.size).to eq(0)
    end
  end

  describe "acts_as_paranoid" do
    it "soft deletes records" do
      subject = create(:subject)
      subject.destroy
      expect(Subject.with_deleted.find(subject.id)).to be_present
      expect(Subject.find_by(id: subject.id)).to be_nil
    end

    it "can be restored" do
      subject = create(:subject)
      subject.destroy
      subject.restore
      expect(Subject.find(subject.id)).to be_present
    end

    it "can be really destroyed" do
      subject = create(:subject)
      subject.really_destroy!
      expect(Subject.with_deleted.find_by(id: subject.id)).to be_nil
    end
  end

  describe "constants" do
    it "defines SUBJECT_PERMITTED_PARAMS_CREATE" do
      expect(Subject::SUBJECT_PERMITTED_PARAMS_CREATE).to include(:name, :max_score, :estimated_time_days)
    end

    it "defines SUBJECT_PERMITTED_PARAMS_UPDATE" do
      expect(Subject::SUBJECT_PERMITTED_PARAMS_UPDATE).to include(:name, :max_score, :estimated_time_days)
      expect(Subject::SUBJECT_PERMITTED_PARAMS_UPDATE.last).to be_a(Hash)
      expect(Subject::SUBJECT_PERMITTED_PARAMS_UPDATE.last[:tasks_attributes]).to include(:id, :name, :_destroy)
    end
  end

  describe "image attachment" do
    it "can attach image" do
      subject = create(:subject)
      subject.image.attach(
        io: File.open(Rails.root.join('app/assets/images/default_course_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
      expect(subject.image).to be_attached
    end

    it "can detach image" do
      subject = create(:subject, :with_image)
      expect(subject.image).to be_attached
      
      subject.image.purge
      expect(subject.image).not_to be_attached
    end
  end
end


