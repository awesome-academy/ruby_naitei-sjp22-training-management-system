class CourseSupervisor < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: {scope: :course_id}

  # Scopes
  scope :by_course, ->(course) {where(course: course)}
  scope :by_user, ->(user) {where(user: user)}
  scope :recent, -> {order(created_at: :desc)}
end
