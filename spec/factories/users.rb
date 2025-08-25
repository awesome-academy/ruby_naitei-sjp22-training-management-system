# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }

    sequence(:email) {|n| "test#{n}@example.com"}
    password {"password123"}
    password_confirmation {"password123"}

    birthday {Faker::Date.birthday(min_age: 18, max_age: 65)}

    # enums
    gender {User.genders.keys.sample}
    role {:trainee}

    # Devise-related
    confirmed_at {Time.current}
    from_google_oauth {false}

    # Traits
    trait :trainee do
      role {:trainee}
    end

    trait :supervisor do
      role {:supervisor}
    end

    trait :admin do
      role {:admin}
    end

    trait :unconfirmed do
      confirmed_at {nil}
      confirmation_token {Devise.friendly_token}
      confirmation_sent_at {Time.current}
    end

    trait :from_google do
      from_google_oauth {true}
      confirmed_at {Time.current}
    end
  end
end
