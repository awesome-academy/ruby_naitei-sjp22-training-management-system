class UserCourse < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :course
  have_many :user_subjects, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: {scope: :course_id}

  # Callbacks
  before_create :set_joined_at

  # Scopes
  scope :active, -> {where(finished_at: nil)}
  scope :completed, -> {where.not(finished_at: nil)}
  scope :by_user, ->(user) {where(user: user)}
  scope :by_course, ->(course) {where(course: course)}
  scope :recent, -> {order(joined_at: :desc)}
end
