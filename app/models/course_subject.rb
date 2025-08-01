class CourseSubject < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :subject
  has_many :tasks, as: :taskable, dependent: :destroy

  # Validations
  validates :course_id, uniqueness: {scope: :subject_id}
  validates :position,
            numericality: {
              greater_than_or_equal_to: Settings.course_subject.min_position
            },
            allow_nil: true
  validate :finish_date_after_start_date

  # Scopes
  scope :ordered_by_position, -> {order(:position)}
  scope :by_course, ->(course) {where(course: course)}
  scope :by_subject, ->(subject) {where(subject: subject)}
  scope :active, lambda {    where(
                     start_date: ..Date.current,
                     finish_date: Date.current..
)
  }

  private

  def finish_date_after_start_date
    return unless start_date && finish_date

    return unless finish_date < start_date

    errors.add(:finish_date,
               Settings.error_messages.finish_date_after_start_date)
  end
end
