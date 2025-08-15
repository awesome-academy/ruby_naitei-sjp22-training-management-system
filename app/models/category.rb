class Category < ApplicationRecord
  include Positionable

  CATERGORY_PERMITTED_PARAMS = [:name,
  {subject_categories_attributes: [:id, :subject_id, :position,
:_destroy]}].freeze

  # Associations
  has_many :subject_categories, dependent: :destroy
  has_many :subjects, through: :subject_categories

  accepts_nested_attributes_for :subject_categories, allow_destroy: true

  # Validations
  validates :name, presence: true, uniqueness: {case_sensitive: false},
                  length: {
                    maximum: Settings.category.max_name_length
                  }
  validate :subject_category_positions_are_unique
  # Scopes
  scope :ordered_by_name, -> {order(:name)}
  scope :search_by_name, (lambda do |query|
                            if query.present?
                              where("name LIKE ?",
                                    "%#{sanitize_sql_like(query)}%")
                            end
                          end)
  scope :recent, -> {order(created_at: :desc)}

  private

  def positionable_association_name
    :subject_categories
  end

  def subject_category_positions_are_unique
    active_positions = subject_categories.reject(&:marked_for_destruction?)
                                         .map(&:position)
                                         .compact

    if active_positions.present? && active_positions
       .uniq.length != active_positions.length
      errors.add(:base)
    end
  end
end
