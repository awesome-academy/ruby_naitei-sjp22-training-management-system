class Subject < ApplicationRecord
  acts_as_paranoid

  SUBJECT_PERMITTED_PARAMS_CREATE = %i(name max_score
                                        estimated_time_days).freeze
  SUBJECT_PERMITTED_PARAMS_UPDATE = [
    :name, :max_score, :estimated_time_days,
    {tasks_attributes: %i(id name _destroy)}
  ].freeze

  # Associations
  has_many :course_subjects # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :user_subjects, through: :course_subjects
  has_many :users, through: :user_subjects

  has_many :courses, through: :course_subjects
  has_many :subject_categories, dependent: :destroy
  has_many :categories, through: :subject_categories
  has_many :tasks, as: :taskable, dependent: :destroy
  has_one_attached :image
  accepts_nested_attributes_for :tasks, allow_destroy: true,
                              reject_if: (lambda do |attributes|
                                attributes[Settings.name].blank?
                              end)

  # Validations
  validates :name, presence: true,
            uniqueness: {case_sensitive: false},
            length: {maximum: Settings.subject.max_name_length}
  validates :max_score, presence: true,
            numericality: {
              only_integer: true,
              greater_than: Settings.digits.digit_zero,
              less_than_or_equal_to: Settings.subject.max_score_limit,
              allow_blank: true
            }
  validates :estimated_time_days, presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              allow_blank: true
            }
  validates :image,
            content_type: {
              in: Settings.subject.allowed_image_types,
              message: :invalid_image_type
            },
            size: {
              less_than: Settings.subject.max_image_size.megabytes,
              message: :image_size_exceeded,
              size: Settings.subject.max_image_size.megabytes
            }

  # Scopes
  scope :ordered_by_name, -> {order(:name)}
  scope :search_by_name, (lambda do |query|
                            if query.present?
                              where("name LIKE ?",
                                    "%#{sanitize_sql_like(query)}%")
                            end
                          end)
  scope :recent, -> {order(created_at: :desc)}
end
