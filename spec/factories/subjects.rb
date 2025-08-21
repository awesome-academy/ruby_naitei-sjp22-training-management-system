FactoryBot.define do
  factory :subject do
    sequence(:name) {|n| "Subject #{n} #{Faker::Educator.subject}"}
    max_score {100}
    estimated_time_days {Faker::Number.between(from: 7, to: 60)}

    trait :deleted do
      deleted_at {Time.current}
    end
  end
end
  