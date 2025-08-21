FactoryBot.define do
  factory :course_subject do
    association :course
    association :subject
    position {Faker::Number.between(from: 1, to: 10)}
    start_date {Faker::Date.forward(days: 10)}
    finish_date {Faker::Date.between(from: start_date, to: start_date + 3.months)}

    trait :with_deleted_subject do
      association :subject, :deleted
    end
  end
end
