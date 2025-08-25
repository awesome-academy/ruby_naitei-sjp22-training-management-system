# frozen_string_literal: true

# ==============================================================================
# GHI CHÚ QUAN TRỌNG TRƯỚC KHI CHẠY
# ==============================================================================
# 1. Yêu cầu Gem:
#    File này sử dụng gem 'faker' để tạo dữ liệu giả.
#    Hãy chắc chắn bạn đã thêm `gem 'faker'` vào Gemfile của mình.
#
# 2. File ảnh mẫu:
#    Để seed thành công, bạn CẦN tạo các file ảnh mẫu tại đường dẫn:
#    - `app/assets/images/default_user_image.png`
#    - `app/assets/images/default_course_image.png`
#
# 3. Thời gian thực thi:
#    Quá trình seed này tạo ra một lượng lớn dữ liệu (~40 khóa học và hàng chục nghìn
#    bản ghi liên quan). Việc này có thể mất vài phút để hoàn thành.
# ==============================================================================

# ==============================================================================
# SERVICE ĐỂ TẠO DỮ LIỆU CHI TIẾT CHO MỘT KHÓA HỌC
# (Đóng gói logic phức tạp để giữ cho script chính gọn gàng)
# ==============================================================================
class CourseSeederService
  def initialize(course, all_trainees)
    @course = course
    @all_trainees = all_trainees
    @today = Time.zone.today
  end

  def seed!
    puts "    -> Bắt đầu tạo dữ liệu cho Khóa học: '#{@course.name}'"
    seed_course_subjects_and_tasks
    seed_trainees_and_all_related_data
    puts "    -> Hoàn tất dữ liệu cho Khóa học: '#{@course.name}'\n"
  end

  private

  # Tạo CourseSubjects, clone tasks từ Subject gốc, và tạo thêm task riêng cho khóa học
  def seed_course_subjects_and_tasks
    subjects_for_course = Subject.all.sample(rand(6..12))
    subjects_for_course.each_with_index do |subject, index|
      estimated_days = subject.estimated_time_days || 10
      cs_start = @course.start_date + (index * estimated_days).days
      cs_finish = cs_start + (estimated_days - 1).days
      cs_finish = [@course.finish_date, cs_finish].min
      cs_start = cs_finish if cs_start > cs_finish
      course_subject = @course.course_subjects.create!(
        subject:, position: index + 1,
        start_date: cs_start, finish_date: cs_finish
      )
      rand(3..8).times.each_with_index do |_, i|
        course_subject.tasks.create!(
          name: "#{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.adjective} #{Faker::Hacker.noun} #{Faker::Number.unique.number(digits: 4)} #{i + 1}"
        )
      end
    end
    @course.reload
  end

  # Tạo học viên và tất cả dữ liệu liên quan
  # LƯU Ý: Việc tạo UserCourse sẽ kích hoạt callback để tự động tạo UserSubject và UserTask
  def seed_trainees_and_all_related_data
    trainees_for_course = @all_trainees.sample(rand(20..30))
    trainees_for_course.each do |trainee|
      next if @course.users.exists?(trainee.id)

      # Bước 1: Tạo UserCourse. Hành động này sẽ kích hoạt callback `after_create`
      # trong model UserCourse để tự động tạo ra các UserSubject và UserTask mặc định.
      user_course = @course.user_courses.create!(user: trainee, joined_at: @course.start_date, status: @course.status)

      # Bước 2: Cập nhật các bản ghi vừa được tạo với dữ liệu thực tế hơn.
      update_user_subjects_and_tasks_for(user_course)

      # Bước 3: Tạo các báo cáo hàng ngày.
      seed_daily_reports_for(user_course)
    end
  end

  # ==========================================================================
  # FIX DỨT ĐIỂM: Thay đổi toàn bộ logic của phương thức này.
  # Thay vì TẠO MỚI (gây xung đột với callback), chúng ta sẽ TÌM VÀ CẬP NHẬT
  # các bản ghi UserSubject/UserTask đã được callback tự động tạo ra.
  # ==========================================================================
  def update_user_subjects_and_tasks_for(user_course)
    finished_statuses = [
      Settings.user_subject.status.finished_early,
      Settings.user_subject.status.finished_ontime,
      Settings.user_subject.status.finished_but_overdue
    ]

    # Lấy tất cả các UserSubject vừa được callback tạo ra để cập nhật chúng
    user_course.user_subjects.includes(:course_subject, :user_tasks).each do |user_subject|
      cs = user_subject.course_subject
      status, started_at, completed_at = determine_user_subject_status_and_dates(cs)
      score = finished_statuses.include?(status) ? rand(5.0..10.0).round(1) : nil

      # Cập nhật UserSubject
      user_subject.update!(
        status:,
        score:,
        started_at:,
        completed_at:
      )

      next if user_subject.not_started?

      # Cập nhật các UserTask liên quan
      if finished_statuses.include?(user_subject.status_before_type_cast)
        # Nếu môn học đã xong, đánh dấu tất cả task là "done"
        user_subject.user_tasks.update_all(status: Settings.user_task.status.done)
      else
        # Nếu môn học đang diễn ra, cập nhật trạng thái task một cách ngẫu nhiên
        user_subject.user_tasks.each do |user_task|
          task_status = [Settings.user_task.status.not_done, Settings.user_task.status.done].sample
          user_task.update!(status: task_status)
        end
      end
    end
  end

  # Logic để xác định trạng thái và ngày tháng cho UserSubject
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

    if @today.between?(cs.start_date, cs.finish_date)
      if rand < 0.2
        possible_completion_date = cs.finish_date - rand(1..3).days
        if possible_completion_date <= @today
          return [Settings.user_subject.status.finished_early, started_at, possible_completion_date]
        end
      end
      return [Settings.user_subject.status.in_progress, started_at, nil]
    end

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

    [Settings.user_subject.status.in_progress, started_at, nil]
  end

  # Tạo các báo cáo hàng ngày cho học viên
  def seed_daily_reports_for(user_course)
    trainee = user_course.user
    course = user_course.course
    start_day = course.start_date
    end_day = [@today, course.finish_date].min
    return if start_day > end_day

    (start_day..end_day).each do |date|
      next if date.saturday? || date.sunday?
      next if rand > 0.85

      report_status = rand > 0.2 ? Settings.daily_report.status.submitted : Settings.daily_report.status.draft
      DailyReport.create!(
        user: trainee, course:, content: Faker::Lorem.paragraph(sentence_count: rand(3..6)),
        status: report_status,
        created_at: date.at_beginning_of_day, updated_at: date.at_beginning_of_day
      )
    end
  end
end

# ==============================================================================
# MAIN SEEDING SCRIPT
# ==============================================================================

puts "======================================================"
puts "=> Bắt đầu quá trình seeding dữ liệu..."

# --- Bước 0: Chuẩn bị và kiểm tra ---
user_image_path = Rails.root.join("app", "assets", "images", "default_user_image.png")
course_image_path = Rails.root.join("app", "assets", "images", "default_course_image.png")
unless File.exist?(user_image_path) && File.exist?(course_image_path)
  puts "\n\n!!! LỖI: Không tìm thấy file ảnh mẫu."
  puts "Vui lòng tạo 'default_user_image.png' và 'default_course_image.png' trong 'app/assets/images/' và chạy lại.\n\n"
  exit
end

ActiveRecord::Base.transaction do
  # --- Bước 1: Tạo các dữ liệu lõi (Users, Categories) ---
  puts "-> Đang tạo Users (Admins, Supervisors, Trainees)..."
  3.times do |n|
    User.find_or_create_by!(email: "admin-#{n + 1}@example.com") do |user|
      user.name = "Admin User #{n+1}"
      user.password = "password"
      user.password_confirmation = "password"
      user.role = Settings.user.roles.admin
      user.gender = Settings.user.genders.male
      user.birthday = 30.years.ago
      user.skip_confirmation!
    end
  end
  3.times do |n|
    User.find_or_create_by!(email: "supervisor-#{n + 1}@example.com") do |user|
      user.name = "Supervisor #{n + 1}"
      user.password = "password"
      user.password_confirmation = "password"
      user.role = Settings.user.roles.supervisor
      user.gender = User.genders.keys.sample
      user.birthday = Faker::Date.birthday(min_age: 28, max_age: 50)
      user.skip_confirmation!
    end
  end
  10.times do |n|
    User.find_or_create_by!(email: "trainee-#{n + 1}@example.com") do |user|
      user.name = Faker::Name.name
      user.password = "password"
      user.password_confirmation = "password"
      user.role = Settings.user.roles.trainee
      user.gender = User.genders.keys.sample
      user.birthday = Faker::Date.birthday(min_age: 20, max_age: 24)
      user.skip_confirmation!
    end
  end
  supervisors = User.supervisor.to_a
  trainees = User.trainee.to_a
  puts "   + Đã tạo/cập nhật: #{User.admin.count} Admins, #{supervisors.count} Supervisors, #{trainees.count} Trainees."

  puts "-> Đang tạo Categories và Subjects..."
  categories = 10.times.map { |i| Category.find_or_create_by!(name: "Category #{i}: #{Faker::Educator.unique.subject.capitalize}") }
  category_positions = Hash.new(0)
  subjects = 50.times.map do |i|
    subject_name = "Subject #{i}: #{Faker::ProgrammingLanguage.name}: #{Faker::Educator.course_name}"
    subject = Subject.with_deleted.find_or_create_by!(name: subject_name) do |s|
      s.max_score = Settings.subject.default_max_score
      s.estimated_time_days = rand(5..15)
    end
    subject.restore if subject.deleted?
    unless subject.image.attached?
      subject.image.attach(io: File.open(user_image_path), filename: "default_subject_image.png")
    end

    selected_categories = categories.sample(rand(1..3))
    selected_categories.each do |category|
      category_positions[category.id] += 1
      SubjectCategory.find_or_create_by!(subject: subject, category: category) do |sc|
        sc.position = category_positions[category.id]
      end
    end
    subject
  end
  puts "   + Đã tạo/cập nhật: #{categories.count} Categories, #{subjects.count} Subjects."

  puts "-> Đang tạo các Task Template cho mỗi Subject..."
  subjects.each do |subject|
    if subject.tasks.empty?
      rand(4..6).times do |i|
        subject.tasks.create!(
          name: "Template Task ##{i + 1} for Subject #{subject.id}: #{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.adjective} module"
        )
      end
    end
  end
  puts "   + Tổng cộng: #{Task.where(taskable_type: "Subject").count} task templates."

  puts "\n-> Đang tạo các Khóa học và dữ liệu liên quan..."

  # Tạo các khóa học ĐÃ KẾT THÚC
  puts "\n  -> Tạo 10 khóa học ĐÃ KẾT THÚC..."
  3.times.each_with_index do |_, i|
    course_name = "#{Faker::Company.industry.capitalize} (Finished) #{i + 1}"
    course = Course.find_or_create_by!(name: course_name) do |c|
      c.user = supervisors.sample
      c.finish_date = Faker::Date.between(from: 8.months.ago, to: 1.week.ago)
      c.start_date = c.finish_date - rand(3..4).months
      c.status = Settings.course.status.finished
      c.link_to_course = "https://www.#{Faker::Internet.domain_name}"
      c.supervisors = supervisors.sample(rand(1..2))
      c.image.attach(io: File.open(course_image_path), filename: "default_course_image.png")
    end
    CourseSeederService.new(course, trainees).seed!
  end

  # Tạo các khóa học ĐANG DIỄN RA
  puts "\n  -> Tạo 20 khóa học ĐANG DIỄN RA..."
  3.times.each_with_index do |_, i|
    course_name = "#{Faker::Company.industry.capitalize} (In-Progress) #{i + 1}"
    course = Course.find_or_create_by!(name: course_name) do |c|
      c.user = supervisors.sample
      c.start_date = Faker::Date.between(from: 3.months.ago, to: 2.weeks.ago)
      c.finish_date = Faker::Date.between(from: 1.week.from_now, to: 4.months.from_now)
      c.status = Settings.course.status.in_progress
      c.link_to_course = "https://www.#{Faker::Internet.domain_name}"
      c.supervisors = supervisors.sample(rand(1..2))
      c.image.attach(io: File.open(course_image_path), filename: "default_course_image.png")
    end
    CourseSeederService.new(course, trainees).seed!
  end

  # Tạo các khóa học CHƯA BẮT ĐẦU
  puts "\n  -> Tạo 8 khóa học CHƯA BẮT ĐẦU..."
  3.times.each_with_index do |_, i|
    course_name = "#{Faker::Company.industry.capitalize} (Pending) #{i + 1}"
    course = Course.find_or_create_by!(name: course_name) do |c|
      c.user = supervisors.sample
      c.start_date = Faker::Date.between(from: 1.week.from_now, to: 2.months.from_now)
      c.finish_date = c.start_date + rand(3..4).months
      c.status = Settings.course.status.not_started
      c.link_to_course = "https://www.#{Faker::Internet.domain_name}"
      c.supervisors = supervisors.sample(rand(1..2))
      c.image.attach(io: File.open(course_image_path), filename: "default_course_image.png")
    end
    CourseSeederService.new(course, trainees).seed!
  end

  # --- Bước 4: Tạo dữ liệu tương tác (Comments) ---
  puts "\n-> Đang tạo Comments..."
  UserSubject.where.not(status: [Settings.user_subject.status.not_started, Settings.user_subject.status.in_progress]).each do |user_subject|
    next if user_subject.comments.any?
    supervisor = user_subject.user_course.course.supervisors.sample
    next unless supervisor
    comment_content = case user_subject.status
                      when "finished_early" then "Excellent work! Finished well ahead of schedule."
                      when "finished_ontime" then "Good job, completed on time."
                      when "finished_but_overdue" then "Completed, but please mind deadlines."
                      when "overdue_and_not_finished" then "This is overdue. Please complete it ASAP."
                      else "General feedback."
                      end
    user_subject.comments.create!(user: supervisor, content: comment_content)
  end
  puts "   + Đã tạo: #{Comment.count} comments."
end

puts "\n=> Hoàn thành seeding dữ liệu!"
puts "=========================================================="
