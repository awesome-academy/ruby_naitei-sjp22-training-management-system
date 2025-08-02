class Category < ApplicationRecord
  # Associations
  has_many :subject_categories, dependent: :destroy
  has_many :subjects, through: :subject_categories

  # Validations
  validates :name, presence: true,
                  length: {
                    maximum: Settings.category.max_name_length
                  },
                  uniqueness: {case_sensitive: false}

  # Scopes
  scope :ordered_by_name, -> {order(:name)}
end
