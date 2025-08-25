FactoryBot.define do
  factory :user_subject do
    association :user_course
    association :course_subject
    association :user

    status {:in_progress}
    score {rand(0.0..10.0)}
    started_at {Time.current}
    completed_at {nil}

    trait :completed do
      status {:completed}
      completed_at {Time.current}
    end

    trait :in_progress do
      status {:in_progress}
      started_at {Time.current}
      completed_at {nil}
    end
  end
end
