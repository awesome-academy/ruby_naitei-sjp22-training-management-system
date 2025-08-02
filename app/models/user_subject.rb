class UserSubject < ApplicationRecord
  # Enums
  enum status: {new: Settings.user_subject.status.new,
                in_progress: Settings.user_subject.status.in_progress,
                finished_early: Settings.user_subject.status.finished_early,
                finished_late_ontime:
                Settings.user_subject.status.finished_late_ontime,
                finished_but_overdue:
                Settings.user_subject.status.finished_but_overdue,
                overdue_and_not_finished:
                Settings.user_subject.status.overdue_and_not_finished}
  # Associations
  belongs_to :user
  belongs_to :user_course
  belongs_to :course_subject
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :user_tasks, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: {scope: :course_subject_id}
  validates :score,
            numericality: {
              greater_than_or_equal_to: Settings.user_subject.min_score,
              less_than_or_equal_to: Settings.user_subject.max_score
            },
              allow_nil: true

  # Callbacks
  before_create :set_started_at

  # Scopes
  scope :active, -> {where(finished_at: nil)}
  scope :completed, -> {where.not(finished_at: nil)}
  scope :by_user, ->(user) {where(user: user)}
  scope :by_subject, ->(subject) {where(subject: subject)}
  scope :recent, -> {order(started_at: :desc)}
end
