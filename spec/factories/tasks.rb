# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    name {Faker::Lorem.sentence(word_count: 3)}

    trait :deleted do
      deleted_at {Time.current}
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
