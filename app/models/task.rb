class Task < ApplicationRecord
  # Enums
  enum status: {new: Settings.task.status.new,
                in_progress: Settings.task.status.in_progress,
                finished: Settings.task.status.finished}

  # Associations
  belongs_to :taskable, polymorphic: true
  has_many :user_tasks, dependent: :destroy
  has_many :users, through: :user_tasks

  # Validations
  validates :name, presence: true,
length: {maximum: Settings.task.max_name_length}
  validates :description,
            length: {maximum: Settings.task.max_description_length}
  validates :expected_time, numericality: {greater_than: 0}, allow_nil: true

  # Scopes
  scope :ordered_by_name, -> {order(:name)}
  scope :for_taskable, ->(taskable) {where(taskable: taskable)}
end
