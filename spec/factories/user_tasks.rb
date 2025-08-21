FactoryBot.define do
  factory :user_task do
    association :user
    association :task
    association :user_subject
    status { :not_done }
    spent_time {
      Faker::Number.between(
        from: Settings.user_task.min_spent_time + 1,
        to: Settings.user_task.min_spent_time + 100
      )
    }

    trait :done do
      status { :done }
    end

    trait :invalid_spent_time do
      spent_time {
        Faker::Number.between(
          from: Settings.user_task.min_spent_time - 10,
          to: Settings.user_task.min_spent_time - 1
        )
      }
    end

    trait :with_supervisor do
      association :user, factory: [:user, :supervisor]
    end

    trait :with_documents do
      after(:build) do |user_task|
        user_task.documents.attach(
          io: StringIO.new(Faker::Lorem.paragraph),
          filename: "valid_doc.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_invalid_documents do
      after(:build) do |user_task|
        user_task.documents.attach(
          io: StringIO.new(Faker::Lorem.paragraph),
          filename: "invalid_doc.exe",
          content_type: "application/x-msdownload"
        )
      end
    end

    trait :with_large_documents do
      after(:build) do |user_task|
        size = Settings.user_task.max_document_size.megabytes + 1
        user_task.documents.attach(
          io: StringIO.new("a" * size),
          filename: "large_doc.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_max_size_documents do
      after(:build) do |user_task|
        # Tạo file đúng bằng max_document_size
        size = Settings.user_task.max_document_size.megabytes
        user_task.documents.attach(
          io: StringIO.new("a" * size),
          filename: "max_doc.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_less_size_documents do
      after(:build) do |user_task|
        min_size = Settings.user_task.min_document_size.megabytes
        size = [min_size - 1, 1].max
        user_task.documents.attach(
          io: StringIO.new("a" * size),
          filename: "less_doc.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
