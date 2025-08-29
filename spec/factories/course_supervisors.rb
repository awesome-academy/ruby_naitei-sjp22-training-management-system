FactoryBot.define do
  factory :course_supervisor do
    association :course
    association :user
  end
end
