class DailyReport < ApplicationRecord
  DAILY_REPORT_PARAMS = %i(user_id course_id content status).freeze
  EAGER_LOADING_PARAMS = %i(user course).freeze

  # Enums
  enum status: {draft: Settings.daily_report.status.draft,
                submitted: Settings.daily_report.status.submitted}

  # Associations
  belongs_to :user
  belongs_to :course

  delegate :name, to: :course, prefix: true

  # Validations
  validates :content,
            length: {
              minimum: Settings.daily_report.min_content_length,
              maximum: Settings.daily_report.max_content_length
            }
  validate :one_report_per_day, on: :create
  validate :check_user_course_association, on: %i(create update),
            if: -> {course_id.present?}

  # Scopes
  scope :completed, -> {where(is_done: true)}
  scope :pending, -> {where(is_done: false)}
  scope :recent, -> {order(updated_at: :desc)}
  scope :by_user, ->(user_id) {where(user_id:) if user_id.present?}
  scope :by_course, ->(course) {where(course:)}
  scope :by_courses, ->(course_ids) {where(course_ids:)}
  scope :on_day, (lambda do |date|
    return if date.blank?

    processed_date = Date.strptime(date, Settings.params.date)
    where(created_at: processed_date.all_day)
  end)

  def self.ransackable_attributes _auth_object = nil
    %w(content course_id created_at id status updated_at
      user_id created_at_day)
  end

  def self.ransackable_associations _auth_object = nil
    %w(course user)
  end

  ransacker :created_at_day do |_parent|
    Arel.sql("DATE(created_at)")
  end

  private

  def one_report_per_day
    if DailyReport.exists?(user_id:, course_id:,
                           created_at: Time.zone.now.all_day)
      errors.add(:base, :one_report_per_day)
    end
  end

  def check_user_course_association
    return if user&.courses&.exists?(id: course_id)

    errors.add(:course_id, :not_a_valid_course)
  end
end
