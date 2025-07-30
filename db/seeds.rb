User.create!(name: "Example User",
             email: "admin@gmail.com",
             birthday: 25.years.ago,
             gender: "male",
             password: "foobar",
             password_confirmation: "foobar",
             admin: true,
             activated: true,
             activated_at: Time.zone.now)

99.times do |n|
  name = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  birthday = Faker::Date.birthday(min_age: 18, max_age: 65)
  gender = ["male", "female"].sample
  password = "password"
  User.create!(name: name,
               email: email,
               birthday: birthday,
               gender: gender,
               password: password,
               password_confirmation: password,
               activated: true,
               activated_at: Time.zone.now)
end
