FactoryBot.define do
  factory :user_course do
    association :user
    association :course
    status {:not_started}

    trait :in_progress do
      status {:in_progress}
    end

    trait :finished do
      status {:finished}
    end
  end
end
