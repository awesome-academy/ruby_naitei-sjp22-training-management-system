class UserTask < ApplicationRecord
  # Enums
  enum status: {not_done: Settings.user_task.status.not_done,
                done: Settings.user_task.status.done}

  # Associations
  belongs_to :user
  belongs_to :task
  belongs_to :user_subject
  has_many_attached :documents

  # Validations
  validates :user_id, uniqueness: {scope: :task_id}
  validates :spent_time,
            numericality: {
              greater_than_or_equal_to: Settings.user_task.min_spent_time
            },
            allow_nil: true
  validates :documents,
            content_type: {
              in: Settings.user_task.allowed_document_types,
              message: :invalid_document_type
            },
            size: {
              less_than: Settings.user_task.max_document_size.megabytes,
              message: :document_size_exceeded,
              size:
                              Settings.user_task.max_document_size.megabytes
            }

  # Scopes
  scope :by_user, ->(user) {where(user:)}
  scope :by_task, ->(task) {where(task:)}
  scope :by_user_subject, ->(user_subject) {where(user_subject:)}
  scope :recent, -> {order(created_at: :desc)}
end
