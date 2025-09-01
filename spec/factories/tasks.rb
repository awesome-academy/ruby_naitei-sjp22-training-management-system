FactoryBot.define do
  factory :task do
    sequence(:name) { |n| "Task #{n}" }
    association :taskable, factory: :subject

    trait :for_course_subject do
      association :taskable, factory: :course_subject
    end
  end
end
