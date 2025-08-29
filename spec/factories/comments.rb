# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :user
    content {Faker::Lorem.paragraph(sentence_count: 2)}

    association :commentable, factory: :user_subject

    trait :with_user_subject do
      association :commentable, factory: :user_subject
    end

    trait :with_user_course do
      association :commentable, factory: :user_course
    end
  end
end
