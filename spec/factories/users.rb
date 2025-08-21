require "faker" # << THÊM DÒNG NÀY

FactoryBot.define do
  factory :user do
    name {Faker::Name.name}

    sequence(:email) {|n| "test#{n}@example.com"}
    password {"password123"}
    password_confirmation {"password123"}
    birthday {Faker::Date.birthday(min_age: 18, max_age: 65)}

    gender do
      User.genders.keys.sample
    end
    activated {true}
    activated_at {Time.current}

    role {:trainee}

    trait :trainee do
      role {:trainee}
    end

    trait :supervisor do
      role {:supervisor}
    end

    trait :admin do
      role {:admin}
    end
  end
end
