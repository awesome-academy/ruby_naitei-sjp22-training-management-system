# frozen_string_literal: true

FactoryBot.define do
  factory :subject_category do
    association :subject
    association :category
    position {nil} # `nil` is fine as it's not a required field
  end
end
