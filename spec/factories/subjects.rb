FactoryBot.define do
  factory :subject do
    sequence(:name) { |n| "Subject #{n}" }
    max_score { 100 }
    estimated_time_days { 5 }

    trait :with_tasks do
      after(:create) do |subject|
        create_list(:task, 3, taskable: subject)
      end
    end

    trait :with_categories do
      after(:create) do |subject|
        create_list(:subject_category, 2, subject: subject)
      end
    end

    trait :with_image do
      after(:build) do |subject|
        subject.image.attach(
          io: File.open(Rails.root.join('app/assets/images/default_course_image.png')),
          filename: 'subject_image.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
