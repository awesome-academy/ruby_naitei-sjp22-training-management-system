# spec/factories/daily_reports.rb

FactoryBot.define do
  factory :daily_report do
    association :user
    association :course
    content { Faker::Lorem.paragraph }
    status { :draft }

    trait :submitted do
      status { :submitted }
    end
  end
end
