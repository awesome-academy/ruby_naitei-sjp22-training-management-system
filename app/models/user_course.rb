class UserCourse < ApplicationRecord
  USER_COURSE_INCLUDES = [:comments, {
    user_subjects: [:comments, :user_tasks]
  }].freeze

  # Enums
  enum status: {not_started: Settings.user_course.status.not_started,
                in_progress: Settings.user_course.status.in_progress,
                finished: Settings.user_course.status.finished}

  # Associations
  belongs_to :user
  belongs_to :course
  has_many :user_subjects, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: {scope: :course_id}

  # Callbacks
  after_create :create_user_subjects_for_course_subjects, if: :trainee?

  # Scopes
  scope :active, -> {where(finished_at: nil)}
  scope :completed, -> {where.not(finished_at: nil)}
  scope :by_user, ->(user) {where(user:)}
  scope :by_course, ->(course) {where(course:)}
  scope :recent, -> {order(joined_at: :desc)}
  scope :trainees, (lambda do
    joins(:user).where(users: {role: :trainee}).includes(:user)
  end)

  def self.ransackable_attributes _auth_object = nil
    %w(course_id created_at finished_at id joined_at status
      updated_at user_id)
  end

  private

  def trainee?
    user&.trainee?
  end

  def create_user_subjects_for_course_subjects
    # Create user_subjects and user_tasks for all existing course_subjects
    course.course_subjects.includes(:tasks).find_each do |course_subject|
      user_subject = user_subjects.create!(
        user: user,
        course_subject: course_subject,
        status: Settings.user_subject.status.not_started
      )

      # Create user_tasks for all tasks of the course_subject
      course_subject.tasks.each do |task|
        user_subject.user_tasks.create!(
          user: user,
          task: task,
          status: Settings.user_task.status.not_done
        )
      end
    end
  end
end
