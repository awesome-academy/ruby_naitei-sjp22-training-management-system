class DailyReport < ApplicationRecord
  # Enums
  enum is_done: {pending: Settings.daily_report.status.pending,
                 completed: Settings.daily_report.status.completed}

  # Associations
  belongs_to :user
  belongs_to :course

  # Validations
  validates :content,
            length: {maximum: Settings.daily_report.max_content_length}

  # Scopes
  scope :completed, -> {where(is_done: true)}
  scope :pending, -> {where(is_done: false)}
  scope :recent, -> {order(created_at: :desc)}
  scope :by_user, ->(user) {where(user: user)}
  scope :by_course, ->(course) {where(course: course)}
end
