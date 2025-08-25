# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    sequence(:name) {|n| "Course #{n} #{Faker::Educator.course_name}"}
    start_date {Faker::Date.forward(days: 30)}
    finish_date {Faker::Date.between(from: start_date, to: start_date + 6.months)}
    association :user, factory: :user, role: :supervisor
    status {Course.statuses.keys.sample}
    link_to_course {"https://www.#{Faker::Internet.domain_name}"}

    trait :in_progress do
      start_date {Date.today - 1.week}
      finish_date {Date.today + 1.week}
    end

    trait :finished do
      start_date {Date.today - 2.months}
      finish_date {Date.today - 1.month}
    end
  end
end
