class UserSubject < ApplicationRecord
  # Enums
  enum status: {not_started: Settings.user_subject.status.not_started,
                in_progress: Settings.user_subject.status.in_progress,
                finished_early: Settings.user_subject.status.finished_early,
                finished_ontime: Settings.user_subject.status.finished_ontime,
                finished_but_overdue: Settings.user_subject.status
                                              .finished_but_overdue,
                overdue_and_not_finished: Settings.user_subject.status
                                                  .overdue_and_not_finished}
  # Associations
  belongs_to :user
  belongs_to :user_course
  belongs_to :course_subject
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :user_tasks, dependent: :destroy

  # Validations
  validates :user_id,
            uniqueness: {scope: [:course_subject_id, :user_course_id]}
  validates :score,
            numericality: {
              greater_than_or_equal_to: Settings.user_subject.min_score,
              less_than_or_equal_to: Settings.user_subject.max_score
            },
              allow_nil: true

  # Scopes
  scope :active, -> {where(completed_at: nil)}
  scope :completed, -> {where.not(completed_at: nil)}
  scope :for_course, (lambda do |course|
    joins(:course_subject).where(course_subject: {course:})
  end)
  scope :by_user, ->(user) {where(user:)}
  scope :by_subject, ->(subject) {where(subject:)}
  scope :recent, -> {order(started_at: :desc)}

  def display_status
    return Settings.user_subject.display_status.not_started unless started_at

    if completed_at
      determine_finished_status
    elsif overdue?
      Settings.user_subject.display_status.overdue_and_not_finished
    else
      Settings.user_subject.display_status.in_progress
    end
  end

  def overdue?
    return false unless course_subject.finish_date

    Date.current > course_subject.finish_date
  end

  def comment_count
    comments.length
  end

  private

  def determine_finished_status
    return finished_ontime_status unless course_subject.finish_date

    compare_completion_with_deadline
  end

  def finished_ontime_status
    Settings.user_subject.display_status.finished_ontime
  end

  def compare_completion_with_deadline
    completion_date = completed_at.to_date
    deadline = course_subject.finish_date

    if completion_date < deadline
      Settings.user_subject.display_status.finished_early
    elsif completion_date == deadline
      Settings.user_subject.display_status.finished_ontime
    else
      Settings.user_subject.display_status.finished_but_overdue
    end
  end
end
