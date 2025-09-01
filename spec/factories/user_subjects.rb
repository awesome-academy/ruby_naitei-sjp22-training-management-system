FactoryBot.define do
  factory :user_subject do
    association :user
    association :user_course
    association :course_subject
    status { :not_started }
  end
end
