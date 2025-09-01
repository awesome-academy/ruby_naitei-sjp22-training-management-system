FactoryBot.define do
  factory :user_task do
    association :user
    association :task
    status { :not_done }
  end
end
