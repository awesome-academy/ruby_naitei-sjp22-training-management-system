FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "Course #{n}" }
    association :user, factory: [:user, :supervisor]
    link_to_course { "https://example.com" }
    start_date { Date.today }
    finish_date { Date.today + 30.days }
    supervisor_ids { [] }

    after(:build) do |course|
      course.image.attach(
        io: File.open(Rails.root.join('app/assets/images/default_course_image.png')),
        filename: 'course_image.png',
        content_type: 'image/png'
      )
    end

    trait :with_supervisors do
      after(:create) do |course|
        supervisors = create_list(:user, 2, :supervisor)
        course.supervisor_ids = supervisors.map(&:id)
        course.save!
      end
    end
  end
end
