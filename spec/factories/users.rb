FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    birthday { Date.today - 20.years }
    gender { :male }
    role { :trainee }
    activated { true }

    trait :supervisor do
      role { :supervisor }
    end

    trait :admin do
      role { :admin }
    end

    trait :trainee do
      role { :trainee }
    end

    trait :inactive do
      activated { false }
    end
  end
end
