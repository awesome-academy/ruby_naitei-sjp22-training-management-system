class Comment < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :commentable, polymorphic: true

  # Validations
  validates :content, presence: true,
              length: {
                minimum: Settings.comment.min_content_length,
                maximum: Settings.comment.max_content_length
              }

  # Scopes
  scope :recent, -> {order(created_at: :desc)}
  scope :oldest_first, -> {order(created_at: :asc)}
  scope :by_user, ->(user) {where(user: user)}
  scope :for_commentable, ->(commentable) {where(commentable: commentable)}
end
