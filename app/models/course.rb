class Course < ApplicationRecord
  # Enums
  enum status: {not_started: Settings.course.status.not_started,
                in_progress: Settings.course.status.in_progress,
                finished: Settings.course.status.finished}

  # Associations
  belongs_to :user
  has_many :user_courses, dependent: :destroy
  has_many :users, through: :user_courses
  has_many :daily_reports, dependent: :destroy
  has_many :course_subjects, dependent: :destroy
  has_many :subjects, through: :course_subjects
  has_many :course_supervisors, dependent: :destroy
  has_many :supervisors, through: :course_supervisors, source: :user
  has_one_attached :image

  # Validations
  validates :name, presence: true,
            length: {
              maximum: Settings.course.max_name_length
            }
  validate :finish_date_after_start_date
  validates :image,
            content_type: {
              in: Settings.course.allowed_image_types,
              message: :invalid_image_type
            },
            size: {
              less_than: Settings.course.max_image_size.megabytes,
              message: :image_size_exceeded,
              size: Settings.course.max_image_size.megabytes
            }

  # Scopes
  scope :upcoming, -> {where(start_date: Date.current.next_day..)}
  scope :completed, -> {where(finish_date: ..Date.current.prev_day)}
  scope :ordered_by_start_date, -> {order(:start_date)}
  scope :by_status, ->(status) {where(status:) if status.present?}
  scope :search_by_name, lambda {|query|
                           if query.present?
                             where("name LIKE ?",
                                   "%#{sanitize_sql_like(query)}%")
                           end
                         }
  scope :resent, -> {order(created_at: :desc).limit(Settings.course.limit_recent)}

  def trainee_count
    user_courses.trainees.count
  end

  def trainer_count
    supervisors.count
  end

  def subject_count
    subjects.count
  end

  private

  def finish_date_after_start_date
    return unless start_date && finish_date

    return unless finish_date < start_date

    errors.add(:finish_date,
               I18n.t("shared.error_messages.finish_date_after_start_date"))
  end
end
