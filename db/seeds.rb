# frozen_string_literal: true

# Ghi chú quan trọng:
# Để seed thành công, bạn cần tạo một file ảnh mẫu tại đường dẫn:
# db/seed_images/default_course_image.png
# File này sẽ được dùng làm ảnh đại diện mặc định cho các khóa học được tạo.

# Service để tạo dữ liệu chi tiết cho một khóa học
class CourseSeederService
  # Đã loại bỏ @all_supervisors vì không còn cần thiết sau khi sửa lỗi
  def initialize(course, all_trainees)
    @course = course
    @all_trainees = all_trainees
    @today = Time.zone.today
  end

  def seed!
    puts "    -> Bắt đầu tạo dữ liệu cho Khóa học: '#{@course.name}'"
    # seed_supervisors đã được chuyển ra ngoài, không cần gọi ở đây nữa
    seed_course_subjects_and_tasks
    seed_trainees_and_all_related_data
    puts "    -> Hoàn tất dữ liệu cho Khóa học: '#{@course.name}'\n"
  end

  private

  # Phương thức này đã được chuyển logic ra ngoài, không cần thiết trong Service nữa.
  # def seed_supervisors
  #   @course.supervisors = @all_supervisors.sample(rand(1..2))
  # end

  def seed_course_subjects_and_tasks
    subjects_for_course = Subject.all.sample(rand(6..12))
    subjects_for_course.each_with_index do |subject, index|
      estimated_days = subject.estimated_time_days || 10
      cs_start = @course.start_date + (index * estimated_days).days
      cs_finish = cs_start + (estimated_days - 1).days
      cs_finish = [@course.finish_date, cs_finish].min
      cs_start = cs_finish if cs_start > cs_finish

      course_subject = @course.course_subjects.create!(
        subject: subject, position: index + 1,
        start_date: cs_start, finish_date: cs_finish
      )
      # Tạo tasks cho mỗi course_subject
      rand(3..8).times.each_with_index do |_, i|
        course_subject.tasks.create!(
          name: "#{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.adjective} #{Faker::Hacker.noun} #{Faker::Number.unique.number(digits: 4)} #{i + 1}"
        )
      end
    end
    @course.reload
  end

  def seed_trainees_and_all_related_data
    trainees_for_course = @all_trainees.sample(rand(20..30))
    trainees_for_course.each do |trainee|
      # Kiểm tra để đảm bảo không thêm trainee đã có trong khóa học
      next if @course.users.exists?(trainee.id)

      user_course = @course.user_courses.create!(user: trainee, joined_at: @course.start_date, status: @course.status)
      seed_user_subjects_and_tasks_for(user_course)
      seed_daily_reports_for(user_course)
    end
  end

  def seed_user_subjects_and_tasks_for(user_course)
    trainee = user_course.user
    user_course.course.course_subjects.each do |cs|
      status, started_at, completed_at = determine_user_subject_status_and_dates(cs)

      finished_statuses = [
        Settings.user_subject.status.finished_early,
        Settings.user_subject.status.finished_ontime,
        Settings.user_subject.status.finished_but_overdue
      ]
      score = finished_statuses.include?(status) ? rand(5.0..10.0).round(1) : nil

      user_subject = user_course.user_subjects.create!(
        user: trainee, course_subject: cs, status: status,
        score: score, started_at: started_at, completed_at: completed_at
      )

      next if user_subject.not_started?

      cs.tasks.each do |task|
        task_status = finished_statuses.include?(user_subject.status_before_type_cast) ?
                      Settings.user_task.status.done :
                      [Settings.user_task.status.not_done, Settings.user_task.status.done].sample
        user_subject.user_tasks.create!(user: trainee, task: task, status: task_status)
      end
    end
  end

  def determine_user_subject_status_and_dates(cs)
    if @course.not_started? || @today < cs.start_date
      return [Settings.user_subject.status.not_started, nil, nil]
    end

    started_at = cs.start_date + rand(-1..1).days
    completed_at = case rand
                   when 0...0.6 then cs.finish_date - rand(1..3).days
                   when 0.6...0.9 then cs.finish_date
                   else cs.finish_date + rand(1..5).days
                   end

    # Logic cho các khóa học đã kết thúc
    if @course.finished?
      return [Settings.user_subject.status.overdue_and_not_finished, started_at, nil] if rand < 0.05
      status = if completed_at < cs.finish_date
                 Settings.user_subject.status.finished_early
               elsif completed_at == cs.finish_date
                 Settings.user_subject.status.finished_ontime
               else
                 Settings.user_subject.status.finished_but_overdue
               end
      return [status, started_at, completed_at]
    end

    # Logic cho các khóa học đang diễn ra
    if @today >= cs.start_date && @today <= cs.finish_date
      if rand < 0.2 # 20% chance to be finished early
        # Ensure completed_at is not in the future
        possible_completion_date = cs.finish_date - rand(1..3).days
        if possible_completion_date <= @today
          return [Settings.user_subject.status.finished_early, started_at, possible_completion_date]
        end
      end
      return [Settings.user_subject.status.in_progress, started_at, nil]
    end

    # Logic cho các môn học đã qua deadline nhưng khóa học vẫn đang chạy
    if @today > cs.finish_date
       return [Settings.user_subject.status.overdue_and_not_finished, started_at, nil] if rand < 0.1
       status = if completed_at < cs.finish_date
                 Settings.user_subject.status.finished_early
               elsif completed_at == cs.finish_date
                 Settings.user_subject.status.finished_ontime
               else
                 Settings.user_subject.status.finished_but_overdue
               end
      return [status, started_at, completed_at]
    end

    # Fallback default
    [Settings.user_subject.status.in_progress, started_at, nil]
  end

  def seed_daily_reports_for(user_course)
    trainee = user_course.user
    course = user_course.course
    start_day = course.start_date
    end_day = [@today, course.finish_date].min
    return if start_day > end_day

    (start_day..end_day).each do |date|
      next if date.saturday? || date.sunday?
      next if rand > 0.85 # Skip some days

      report_status = rand > 0.2 ? Settings.daily_report.status.submitted : Settings.daily_report.status.draft
      DailyReport.create!(
        user: trainee, course: course, content: Faker::Lorem.paragraph(sentence_count: rand(3..6)),
        status: report_status,
        created_at: date.at_beginning_of_day, updated_at: date.at_beginning_of_day
      )
    end
  end
end

#=======================================================
# MAIN SEEDING SCRIPT
#=======================================================

puts "======================================================"
puts "=> Bắt đầu quá trình seeding dữ liệu..."

# Chuẩn bị file ảnh mẫu
# Đảm bảo bạn đã tạo file này tại `db/seed_images/default_course_image.png`
image_path = Rails.root.join("app", "assets", "images", "default_user_image.png")
unless File.exist?(image_path)
  puts "\n\n!!! LỖI: Không tìm thấy file ảnh mẫu tại #{image_path}"
  puts "Vui lòng tạo file ảnh và chạy lại `rails db:seed`.\n\n"
  exit
end

ActiveRecord::Base.transaction do
  puts "-> Đang tạo Users (Admins, Supervisors, Trainees)..."
  5.times do |n|
    User.create!(name: "Admin User", email: "admin-#{n + 1}@example.com", password: "password", password_confirmation: "password",
                 role: Settings.user.roles.admin, gender: Settings.user.genders.male, birthday: 30.years.ago, activated: true, activated_at: Time.zone.now)
  end
  20.times do |n|
    User.create!(name: "Supervisor #{n + 1}", email: "supervisor-#{n + 1}@example.com", password: "password", password_confirmation: "password",
                 role: Settings.user.roles.supervisor, gender: User.genders.keys.sample, birthday: Faker::Date.birthday(min_age: 28, max_age: 50),
                 activated: true, activated_at: Time.zone.now)
  end
  200.times do |n|
    User.create!(name: Faker::Name.name, email: "trainee-#{n + 1}@example.com", password: "password", password_confirmation: "password",
                 role: Settings.user.roles.trainee, gender: User.genders.keys.sample, birthday: Faker::Date.birthday(min_age: 20, max_age: 24),
                 activated: true, activated_at: Time.zone.now)
  end
  supervisors = User.supervisor.to_a
  trainees = User.trainee.to_a

  puts "-> Đang tạo Categories và Subjects..."
  categories = 10.times.map { Category.create!(name: Faker::Educator.unique.subject.capitalize) }
  category_positions = Hash.new(0)
  100.times do
    subject = Subject.create!(name: "#{Faker::ProgrammingLanguage.name}: #{Faker::Educator.course_name}",
                              max_score: Settings.subject.default_max_score, estimated_time_days: rand(5..15))
    selected_categories = categories.sample(rand(1..3))
    selected_categories.each do |category|
      category_positions[category.id] += 1
      subject.subject_categories.create!(category: category, position: category_positions[category.id])
    end
  end

  puts "-> Đang tạo Tasks cho Subject..."
  subjects = Subject.all
  200.times.each_with_index do |_, i|
    Task.create!(
      name: "#{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.adjective} #{Faker::Hacker.noun} #{i + 1}",
      taskable_type: "Subject",
      taskable_id: subjects.sample.id
    )
  end

  puts "\n-> Đang tạo các Khóa học và dữ liệu liên quan..."

  # Tạo các khóa học ĐÃ KẾT THÚC
  10.times.each_with_index do |_, i|
    finish_date = Faker::Date.between(from: 8.months.ago, to: 1.week.ago)
    start_date = finish_date - rand(3..4).months
    # FIX: Gán supervisors ngay khi tạo và bỏ qua validation
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (Finished) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.finished,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    # FIX: Đính kèm ảnh
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  # Tạo các khóa học ĐANG DIỄN RA
  20.times.each_with_index do |_, i|
    start_date = Faker::Date.between(from: 3.months.ago, to: 2.weeks.ago)
    finish_date = Faker::Date.between(from: 1.week.from_now, to: 4.months.from_now)
    # FIX: Gán supervisors ngay khi tạo và bỏ qua validation
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (In-Progress) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.in_progress,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    # FIX: Đính kèm ảnh
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  # Tạo các khóa học CHƯA BẮT ĐẦU
  8.times.each_with_index do |_, i|
    start_date = Faker::Date.between(from: 1.week.from_now, to: 2.months.from_now)
    finish_date = start_date + rand(3..4).months
    # FIX: Gán supervisors ngay khi tạo và bỏ qua validation
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (Pending) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.not_started,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    # FIX: Đính kèm ảnh
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  puts "\n-> Đang tạo Comments với logic nghiệp vụ..."
  finished_or_overdue_user_subjects = UserSubject.where.not(status: [
    Settings.user_subject.status.not_started,
    Settings.user_subject.status.in_progress
  ])

  finished_or_overdue_user_subjects.each do |user_subject|
    supervisor = user_subject.user_course.course.supervisors.sample
    next unless supervisor
    comment_content = case user_subject.status
                      when Settings.user_subject.status.finished_early
                        "Excellent work! Finished well ahead of schedule. Keep it up!"
                      when Settings.user_subject.status.finished_ontime
                        "Good job, completed on time. Solid performance."
                      when Settings.user_subject.status.finished_but_overdue
                        "Completed, but please pay more attention to deadlines next time."
                      when Settings.user_subject.status.overdue_and_not_finished
                        "This subject is overdue and still not finished. Please complete it as soon as possible."
                      else "General feedback on your progress."
                      end
    user_subject.comments.create!(user: supervisor, content: comment_content)
  end

  in_progress_items = UserSubject.in_progress.sample(150) + UserCourse.in_progress.sample(80)
  in_progress_items.each do |item|
    # Comment từ supervisor
    if rand < 0.7
      course = item.is_a?(UserCourse) ? item.course : item.user_course.course
      supervisor = course.supervisors.sample
      next unless supervisor
      item.comments.create!(user: supervisor, content: "Just checking in on your progress.")
    end
    # Comment từ trainee
    if rand < 0.3
      item.comments.create!(user: item.user, content: Faker::Lorem.sentence(word_count: rand(8..20)))
    end
  end
end

puts "\n=> Hoàn thành seeding dữ liệu, đã tuân thủ settings.yml và khắc phục lỗi."
puts "=========================================================="
