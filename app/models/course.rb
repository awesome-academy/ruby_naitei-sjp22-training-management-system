class Course < ApplicationRecord
  # Enums
  enum status: {draft: Settings.course.status.draft,
                active: Settings.course.status.active,
                completed: Settings.course.status.completed,
                cancelled: Settings.course.status.cancelled}

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
              message: Settings.error_messages.invalid_image_type
            },
            size: {
              less_than: Settings.course.max_image_size.megabytes,
              message: t(".image_size_exceeded",
                         size: Settings.course.max_image_size.megabytes)
            }

  # Scopes
  scope :ongoing, lambda {
    where(start_date: ..Date.current, finish_date: Date.current..)
  }
  scope :upcoming, -> { where(start_date: Date.current.next_day..) }
  scope :completed, -> { where(finish_date: ..Date.current.prev_day) }
  scope :ordered_by_start_date, -> { order(:start_date) }

  private

  def finish_date_after_start_date
    return unless start_date && finish_date

    return unless finish_date < start_date

    errors.add(:finish_date,
               Settings.error_messages.finish_date_after_start_date)
  end
end
