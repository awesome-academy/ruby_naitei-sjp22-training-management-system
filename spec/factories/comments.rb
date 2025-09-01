FactoryBot.define do
  factory :comment do
    association :user
    association :commentable, factory: :user_subject
    content { "This is a sample comment" }
  end
end
