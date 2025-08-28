FactoryBot.define do
  factory :task do
    sequence(:name) { |n| "Task #{n} #{Faker::Lorem.words(number: 3).join(' ')}" }
    taskable_type { Settings.task.taskable_type.course_subject } 
    association :taskable, factory: :course_subject

    trait :with_subject_taskable do
      taskable_type { Settings.task.taskable_type.subject }
      association :taskable, factory: :subject
    end

    trait :deleted do
      deleted_at { Time.current } 
    end
    trait :with_subject do
      taskable_type {Subject.name}
      association :taskable, factory: :subject
    end

    trait :with_course_subject do
      taskable_type {CourseSubject.name}
      association :taskable, factory: :course_subject
    end
  end
end
