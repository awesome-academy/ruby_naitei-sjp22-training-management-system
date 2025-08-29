FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "Course-#{n}-#{Faker::Educator.course_name}-#{SecureRandom.uuid}" }
    start_date { Faker::Date.forward(days: 30) }
    finish_date { Faker::Date.between(from: start_date, to: start_date + 6.months) }
    association :user, factory: [:user, :supervisor]
    status { :not_started }
    link_to_course { "https://www.#{Faker::Internet.domain_name}" }

    # attach image nếu có ActiveStorage
    after(:build) do |course|
      if course.respond_to?(:image) && !course.image.attached?
        course.image.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
          filename: "sample.png",
          content_type: "image/png"
        )
      end
    end
    
    before(:create) do |course|
      if course.respond_to?(:supervisors) && course.supervisors.empty?
        course.supervisors << create(:user, :supervisor)
      end
    end

    trait :in_progress do
      start_date { Date.today - 1.week }
      finish_date { Date.today + 1.week }
      status { :in_progress }
    end

    trait :finished do
      start_date { Date.today - 2.months }
      finish_date { Date.today - 1.month }
      status { :finished }
    end
  end
end
