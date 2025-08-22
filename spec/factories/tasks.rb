FactoryBot.define do
  factory :task do
    sequence(:name) { |n| "Task #{n} #{Faker::Lorem.sentence(word_count: 3)}" } 
    taskable_type { Settings.task.taskable_type.course_subject } 
    association :taskable, factory: :course_subject

    trait :with_subject_taskable do
      taskable_type { Settings.task.taskable_type.subject }
      association :taskable, factory: :subject
    end

    trait :deleted do
      deleted_at { Time.current } 
    end
  end
end
