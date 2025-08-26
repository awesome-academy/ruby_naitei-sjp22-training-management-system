class CourseSupervisor < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: {scope: :course_id}

  before_destroy :ensure_course_has_minimum_supervisors

  # Scopes
  scope :by_course, ->(course) {where(course:)}
  scope :by_user, ->(user) {where(user:)}
  scope :recent, -> {order(created_at: :desc)}

  def self.ransackable_attributes _auth_object = nil
    %w(course_id created_at id updated_at user_id)
  end

  private

  def ensure_course_has_minimum_supervisors
    return true unless course&.supervisors

    remaining_count = course.supervisors.count - 1
    return true if remaining_count >= 2

    errors.add(
      :base,
      I18n.t("courses.destroy_supervisor.must_have_another_supervisor")
    )
    throw(:abort)
  end
end
