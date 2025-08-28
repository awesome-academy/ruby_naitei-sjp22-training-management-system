FactoryBot.define do
  factory :user_task do
    association :user
    association :task
    association :user_subject

    status {:not_done}
    spent_time {nil}
  end
end
