FactoryBot.define do
  factory :user_course do
    association :user
    association :course
  end
end
