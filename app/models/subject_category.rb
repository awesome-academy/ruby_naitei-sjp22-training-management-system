class SubjectCategory < ApplicationRecord
  # Associations
  belongs_to :subject
  belongs_to :category

  # Validations
  validates :subject_id, uniqueness: {scope: :category_id}
  validates :position,
            numericality: {
              greater_than_or_equal_to: Settings.subject_category.min_position
            },
            allow_nil: true

  # Scopes
  scope :ordered_by_position, -> {order(:position)}
  scope :by_subject, ->(subject) {where(subject: subject)}
  scope :by_category, ->(category) {where(category: category)}
end
