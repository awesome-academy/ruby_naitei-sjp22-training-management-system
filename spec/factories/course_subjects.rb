FactoryBot.define do
  factory :course_subject do
    association :course
    association :subject

    trait :with_tasks do
      after(:create) do |course_subject|
        create_list(:task, 3, :for_course_subject, taskable: course_subject)
      end
    end
  end
end
