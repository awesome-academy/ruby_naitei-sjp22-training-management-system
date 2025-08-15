# frozen_string_literal: true

# ==============================================================================
# GHI CHÚ QUAN TRỌNG TRƯỚC KHI CHẠY
# ==============================================================================
# 1. Yêu cầu Gem:
#    File này sử dụng gem 'faker' để tạo dữ liệu giả.
#    Hãy chắc chắn bạn đã thêm `gem 'faker'` vào Gemfile của mình.
#
# 2. File ảnh mẫu:
#    Để seed thành công, bạn CẦN tạo một file ảnh mẫu tại đường dẫn:
#    `app/assets/images/default_user_image.png`
#    File này sẽ được dùng làm ảnh đại diện mặc định cho các khóa học và người dùng.
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

      # 1. Clone tasks từ Subject gốc (template) sang CourseSubject
      subject.tasks.each do |original_task|
        cloned_attributes = original_task.attributes.except("id", "taskable_id", "taskable_type", "created_at", "updated_at", "deleted_at")
        course_subject.tasks.create!(cloned_attributes)
      end

      # 2. Tạo thêm các task mới chỉ dành riêng cho CourseSubject này
      rand(1..3).times do |i|
        # ==========================================================================
        # FIX TRIỆT ĐỂ: Tạo tên task theo cấu trúc đơn giản, ngắn gọn và
        # AN TOÀN TUYỆT ĐỐI để không bao giờ bị trùng.
        # Cấu trúc: [Tiền tố] + [ID của CourseSubject] + [Chỉ số] + [Chuỗi ngẫu nhiên]
        # ==========================================================================
        course_subject.tasks.create!(
          name: "CourseTask-CS#{course_subject.id}-#{i + 1}-#{SecureRandom.hex(4)}"
        )
      end
    end
    @course.reload
  end

  # Tạo học viên và tất cả dữ liệu liên quan (user_subjects, user_tasks, daily_reports)
  def seed_trainees_and_all_related_data
    trainees_for_course = @all_trainees.sample(rand(20..30))
    trainees_for_course.each do |trainee|
      next if @course.users.exists?(trainee.id)

      user_course = @course.user_courses.create!(user: trainee, joined_at: @course.start_date, status: @course.status)
      seed_user_subjects_and_tasks_for(user_course)
      seed_daily_reports_for(user_course)
    end
  end

  # Tạo user_subjects và user_tasks cho một học viên trong khóa học
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
        user: trainee, course_subject: cs, status:,
        score:, started_at:, completed_at:
      )

      next if user_subject.not_started?

      cs.tasks.each do |task|
        task_status = if finished_statuses.include?(user_subject.status_before_type_cast)
                        Settings.user_task.status.done
                      else
                        [Settings.user_task.status.not_done, Settings.user_task.status.done].sample
                      end
        user_subject.user_tasks.create!(user: trainee, task:, status: task_status)
      end
    end
  end

  # Logic phức tạp để xác định trạng thái và ngày tháng cho UserSubject dựa trên trạng thái của Khóa học
  def determine_user_subject_status_and_dates(cs)
    # Trường hợp 1: Khóa học chưa bắt đầu HOẶC môn học chưa tới ngày bắt đầu
    if @course.not_started? || @today < cs.start_date
      return [Settings.user_subject.status.not_started, nil, nil]
    end

    started_at = cs.start_date + rand(-1..1).days
    completed_at = case rand
                   when 0...0.6 then cs.finish_date - rand(1..3).days
                   when 0.6...0.9 then cs.finish_date
                   else cs.finish_date + rand(1..5).days
                   end

    # Trường hợp 2: Khóa học đã kết thúc
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

    # Trường hợp 3: Khóa học đang diễn ra
    # 3a: Môn học cũng đang trong thời gian diễn ra
    if @today.between?(cs.start_date, cs.finish_date)
      if rand < 0.2
        possible_completion_date = cs.finish_date - rand(1..3).days
        if possible_completion_date <= @today
          return [Settings.user_subject.status.finished_early, started_at, possible_completion_date]
        end
      end
      return [Settings.user_subject.status.in_progress, started_at, nil]
    end

    # 3b: Môn học đã qua deadline nhưng khóa học vẫn đang chạy
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

  # Tạo các báo cáo hàng ngày cho học viên
  def seed_daily_reports_for(user_course)
    trainee = user_course.user
    course = user_course.course
    start_day = course.start_date
    end_day = [@today, course.finish_date].min
    return if start_day > end_day

    (start_day..end_day).each do |date|
      next if date.saturday? || date.sunday? # Bỏ qua cuối tuần
      next if rand > 0.85 # Bỏ qua một vài ngày để dữ liệu thực tế hơn

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
image_path = Rails.root.join("app", "assets", "images", "default_user_image.png")
unless File.exist?(image_path)
  puts "\n\n!!! LỖI: Không tìm thấy file ảnh mẫu tại #{image_path}"
  puts "Vui lòng tạo file ảnh và chạy lại `rails db:seed`.\n\n"
  exit
end

ActiveRecord::Base.transaction do
  # --- Bước 1: Tạo các dữ liệu lõi (Users, Categories) ---
  puts "-> Đang tạo Users (Admins, Supervisors, Trainees)..."
  5.times do |n|
<<<<<<< Updated upstream
    User.create!(name: "Admin User #{n+1}", email: "admin-#{n + 1}@example.com", password: "password", password_confirmation: "password",
=======
    User.create!(name: "Admin User #{n + 1}", email: "admin-#{n + 1}@example.com", password: "password", password_confirmation: "password",
>>>>>>> Stashed changes
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
  puts "   + Đã tạo: #{User.admin.count} Admins, #{supervisors.count} Supervisors, #{trainees.count} Trainees."

  puts "-> Đang tạo Categories và Subjects..."
  categories = 10.times.map { Category.create!(name: Faker::Educator.unique.subject.capitalize) }
  category_positions = Hash.new(0)
  subjects = 100.times.map do
    subject = Subject.new(name: "#{Faker::ProgrammingLanguage.name}: #{Faker::Educator.course_name}",
                              max_score: Settings.subject.default_max_score, estimated_time_days: rand(5..15))
    subject.image.attach(io: File.open(image_path), filename: "default_subject_image.png")
    subject.save!
    selected_categories = categories.sample(rand(1..3))
    selected_categories.each do |category|
      category_positions[category.id] += 1
      subject.subject_categories.create!(category: category, position: category_positions[category.id])
    end
    subject
  end
<<<<<<< Updated upstream

  # Ghi chú: Việc tạo 'Task' chung cho 'Subject' đã được loại bỏ.
  # Logic tạo Task đã được xử lý trong CourseSeederService để đảm bảo mỗi CourseSubject có Task riêng.
  # Điều này giúp dữ liệu gọn gàng và đúng với logic hơn.
=======
  puts "   + Đã tạo: #{categories.count} Categories, #{subjects.count} Subjects."

  # --- Bước 2: Tạo Task Template cho mỗi Subject ---
  puts "-> Đang tạo các Task Template cho mỗi Subject..."
  subjects.each do |subject|
    rand(4..10).times do |i|
      subject.tasks.create!(
        name: "Template Task ##{i + 1} for Subject #{subject.id}: #{Faker::Hacker.verb.capitalize} the #{Faker::Hacker.adjective} module"
      )
    end
  end
  puts "   + Đã tạo: #{Task.where(taskable_type: "Subject").count} task templates."
>>>>>>> Stashed changes

  # --- Bước 3: Tạo các Khóa học và dữ liệu liên quan chi tiết ---
  puts "\n-> Đang tạo các Khóa học và dữ liệu liên quan..."

  # 3.1. Tạo các khóa học ĐÃ KẾT THÚC
  puts "\n  -> Tạo 10 khóa học ĐÃ KẾT THÚC..."
  10.times.each_with_index do |_, i|
    finish_date = Faker::Date.between(from: 8.months.ago, to: 1.week.ago)
    start_date = finish_date - rand(3..4).months
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (Finished) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.finished,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  # 3.2. Tạo các khóa học ĐANG DIỄN RA
  puts "\n  -> Tạo 20 khóa học ĐANG DIỄN RA..."
  20.times.each_with_index do |_, i|
    start_date = Faker::Date.between(from: 3.months.ago, to: 2.weeks.ago)
    finish_date = Faker::Date.between(from: 1.week.from_now, to: 4.months.from_now)
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (In-Progress) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.in_progress,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  # 3.3. Tạo các khóa học CHƯA BẮT ĐẦU
  puts "\n  -> Tạo 8 khóa học CHƯA BẮT ĐẦU..."
  8.times.each_with_index do |_, i|
    start_date = Faker::Date.between(from: 1.week.from_now, to: 2.months.from_now)
    finish_date = start_date + rand(3..4).months
    course = Course.new(user: supervisors.sample, name: "#{Faker::Company.industry.capitalize} (Pending) #{i + 1}",
                           start_date: start_date, finish_date: finish_date, status: Settings.course.status.not_started,
                           link_to_course: "https://www.#{Faker::Internet.domain_name}",
                           supervisors: supervisors.sample(rand(1..2)))
    course.image.attach(io: File.open(image_path), filename: "default_course_image.png")
    course.save!
    CourseSeederService.new(course, trainees).seed!
  end

  # --- Bước 4: Tạo dữ liệu tương tác (Comments) ---
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
    course = item.is_a?(UserCourse) ? item.course : item.user_course.course
    # Comment từ supervisor
    if rand < 0.7 && (supervisor = course.supervisors.sample)
      item.comments.create!(user: supervisor, content: "Just checking in on your progress. Let me know if you need any help.")
    end
    # Comment từ trainee
    if rand < 0.3
      item.comments.create!(user: item.user, content: Faker::Lorem.sentence(word_count: rand(8..20)))
    end
  end
  puts "   + Đã tạo: #{Comment.count} comments."
end

puts "\n=> Hoàn thành seeding dữ liệu!"
puts "=========================================================="
