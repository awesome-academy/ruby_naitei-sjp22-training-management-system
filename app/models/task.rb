class Task < ApplicationRecord
  acts_as_paranoid

  TASK_PERMITTED_PARAMS = %i(name taskable_id taskable_type).freeze
  TASKABLE_SCOPE = %i(taskable_id taskable_type).freeze

  # Associations
  belongs_to :taskable, -> {with_deleted}, polymorphic: true
  has_many :user_tasks # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :users, through: :user_tasks

  # Validations
  validates :name, presence: true,
            length: {maximum: Settings.task.max_name_length},
            uniqueness: {scope: [:taskable_id, :taskable_type]}

  delegate :name, to: :taskable, prefix: true

  # Scopes
  scope :ordered_by_name, -> {order(:name)}
  scope :for_taskable_type, ->(type) {where(taskable_type: type)}
  scope :search_by_name, (lambda do |query|
                            if query.present?
                              where("name LIKE ?",
                                    "%#{sanitize_sql_like(query)}%")
                            end
                          end)
  scope :recent, -> {order(created_at: :desc)}
end
