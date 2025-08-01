class Subject < ApplicationRecord
  # Associations
  has_many :user_subjects, dependent: :destroy
  has_many :users, through: :user_subjects
  has_many :course_subjects, dependent: :destroy
  has_many :courses, through: :course_subjects
  has_many :subject_categories, dependent: :destroy
  has_many :categories, through: :subject_categories
  has_many :tasks, as: :taskable, dependent: :destroy
  has_one_attached :image

  # Validations
  validates :name, presence: true,
            length: {maximum: Settings.subject.max_name_length}
  validates :max_score, presence: true,
            numericality: {
              greater_than: 0,
              less_than_or_equal_to: Settings.subject.max_score_limit
            }
  validates :estimated_time_days, numericality: {greater_than: 0},
            allow_nil: true
  validates :image,
            content_type: {
              in: Settings.subject.allowed_image_types,
              message: Settings.error_messages.invalid_image_type
            },
            size: {
              less_than: Settings.subject.max_image_size.megabytes,
              message: t(".image_size_exceeded",
                         size: Settings.subject.max_image_size.megabytes)
            }

  # Scopes
  scope :ordered_by_name, -> {order(:name)}
end
