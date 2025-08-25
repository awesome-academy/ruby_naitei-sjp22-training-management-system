class Course < ApplicationRecord
  include Positionable

  COURSE_PARAMS = [
    :name,
    :start_date,
    :finish_date,
    :link_to_course,
    :image,
    {supervisor_ids: []},
    {course_subjects_attributes: [
      :id,
      :subject_id,
      :position,
      :start_date,
      :finish_date,
      :_destroy,
      {tasks_attributes: [
        :id,
        :name,
        :_destroy
      ]}
    ]}
  ].freeze
  IMAGE_DISPLAY_SIZE = [120, 80].freeze
  URL_FORMAT = %r{\Ahttps://.*}

  # Enums
  enum status: {not_started: Settings.course.status.not_started,
                in_progress: Settings.course.status.in_progress,
                finished: Settings.course.status.finished}

  # Associations
  belongs_to :user
  has_many :user_courses, dependent: :destroy
  has_many :users, through: :user_courses
  has_many :daily_reports, dependent: :destroy
  has_many :course_subjects, dependent: :destroy
  has_many :subjects, through: :course_subjects
  has_many :course_supervisors, dependent: :destroy
  has_many :supervisors, through: :course_supervisors, source: :user
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: IMAGE_DISPLAY_SIZE
  end

  accepts_nested_attributes_for :course_subjects, allow_destroy: true

  # Validations
  validates :name, presence: true,
            length: {
              maximum: Settings.course.max_name_length
            },
            uniqueness: {case_sensitive: false}
  validates :link_to_course, presence: true,
            format: {with: URL_FORMAT,
                     message: :must_be_valid_url}
  validates :start_date, presence: true
  validates :finish_date, presence: true
  validate :at_least_one_supervisor_selected
  validate :finish_date_after_start_date
  validate :start_date_within_allowed_range
  validate :finish_date_within_allowed_range
  validates :image, presence: true,
            content_type: {
              in: Settings.course.allowed_image_types,
              message: :invalid_image_type
            },
            size: {
              less_than: Settings.course.max_image_size.megabytes,
              message: :image_size_exceeded,
              size: Settings.course.max_image_size.megabytes
            }
  before_save :update_status_based_on_dates
  after_create :clone_tasks_for_course

  # Scopes
  scope :upcoming, -> {where(start_date: Date.current.next_day..)}
  scope :completed, -> {where(finish_date: ..Date.current.prev_day)}
  scope :ordered_by_start_date, -> {order(:start_date)}
  scope :by_status, ->(status) {where(status:) if status.present?}
  scope :supervised_by, ->(user_id) {where(supervisor_id: user_id)}
  scope :with_counts, (lambda do
    select(
      "courses.*",
      "(SELECT COUNT(*) FROM user_courses
        INNER JOIN users ON users.id = user_courses.user_id
        WHERE user_courses.course_id = courses.id
        AND users.role = #{User.roles[:trainee]}) AS trainees_count",
      "(SELECT COUNT(*) FROM course_supervisors
        INNER JOIN users ON users.id = course_supervisors.user_id
        WHERE course_supervisors.course_id = courses.id
        AND users.role = #{User.roles[:supervisor]}) AS trainers_count"
    )
  end)
  scope :recent, -> {order(created_at: :desc)}
  scope :search_by_name, (lambda do |query|
    if query.present?
      where("name LIKE ?",
            "%#{sanitize_sql_like(query)}%")
    end
  end)
  scope :search_by_trainer_name, (lambda do |query|
    if query.present?
      joins(:supervisors)
        .where("users.name LIKE ?",
               "%#{sanitize_sql_like(query)}%")
        .distinct
    end
  end)
  scope :by_start_date_from, (lambda do |date|
                                where("start_date >= ?", date) if date.present?
                              end)
  scope :by_start_date_to, (lambda do |date|
                              where("start_date <= ?", date) if date.present?
                            end)
  scope :by_trainer, (lambda do |trainer_id|
    if trainer_id.present?
      joins(:course_supervisors)
        .where(course_supervisors: {user_id: trainer_id})
    end
  end)
  scope :filter_by_params, (lambda do |params|
    relation = self

    search_query = params[:search_query]
    if search_query.present?
      relation = if params[:search_type] == Settings.course.creators
                   relation.search_by_trainer_name(search_query)
                 else
                   relation.search_by_name(search_query)
                 end
    end

    relation = relation.by_status(params[:status])
                       .by_start_date_from(params[:start_date_from])
                       .by_start_date_to(params[:start_date_to])

    relation
  end)
  scope :by_course, (lambda do |course_ids|
    where(id: course_ids) if course_ids.present?
  end)
  scope :by_user_course_status, (lambda do |status|
    return all if status.blank?

    includes(:user_courses).where(user_courses: {status:}).distinct
  end)
  scope :by_supervisor_course, (lambda do |supervisor_id|
    return all if supervisor_id.blank?

    joins(:course_supervisors)
    .where(course_supervisors: {user_id: supervisor_id})
  end)

  def trainees_count
    self[:trainees_count] || user_courses
      .joins(:user)
      .where(users: {role: :trainee})
      .count
  end

  def trainee_count
    user_courses.trainees.count
  end

  def trainers_count
    self[:trainers_count] || course_supervisors
      .joins(:user)
      .where(users: {role: :supervisor})
      .count
  end

  def subjects_count
    Course.subjects.count
  end

  private

  def finish_date_after_start_date
    return unless start_date && finish_date

    return unless finish_date < start_date

    errors.add(:finish_date,
               :finish_date_after_start_date)
  end

  def at_least_one_supervisor_selected
    return unless supervisor_ids.blank? || supervisor_ids.compact_blank.empty?

    errors.add(:supervisor_ids,
               :at_least_one_trainer)
  end

  def start_date_within_allowed_range
    return if start_date.blank?
    return if start_date.between?(1.year.ago.to_date, 1.year.from_now.to_date)

    errors.add(:start_date, :must_be_within_one_year_from_now)
  end

  def finish_date_within_allowed_range
    return if finish_date.blank?
    return if finish_date.between?(1.year.ago.to_date, 1.year.from_now.to_date)

    errors.add(:finish_date, :must_be_within_one_year_from_now)
  end

  def filter_and_get_positions
    course_subjects.reject(&:marked_for_destruction?).map(&:position)
  end

  def positionable_association_name
    :course_subjects
  end

  def clone_tasks_for_course
    course_subjects.each do |course_subject|
      subject = course_subject.subject
      next if subject.tasks.blank?

      subject.tasks.each do |original_task|
        cloned_task_attributes = original_task.attributes.except(
          "id",
          "taskable_id",
          "taskable_type",
          "created_at",
          "updated_at"
        )
        raise ActiveRecord::Rollback unless
          course_subject.tasks.create(cloned_task_attributes)
      end
    end
  end

  def update_status_based_on_dates
    return self.status = :not_started unless start_date && finish_date

    today = Date.current

    self.status = if today < start_date
                    :not_started
                  elsif today.between?(start_date, finish_date)
                    :in_progress
                  else
                    :finished
                  end
  end
end
