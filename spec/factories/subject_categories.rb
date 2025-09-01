FactoryBot.define do
  factory :subject_category do
    association :subject
    association :category
    position { 1 }
  end
end
