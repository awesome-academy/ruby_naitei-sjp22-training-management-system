class User < ApplicationRecord
  attr_accessor :remember_token, :session_token, :activation_token,
                :reset_token, :from_google_oauth

  has_secure_password

  # Constants
  PERMITTED_ATTRIBUTES = %i(name email password password_confirmation birthday
gender).freeze
  PASSWORD_RESET_ATTRIBUTES = %i(password password_confirmation).freeze
  PASSWORD_RESET_EXPIRATION = 2.hours.freeze
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  PERMITTED_UPDATE_ATTRIBUTES = %i(name birthday gender).freeze

  # Enums
  enum gender: {
    female: Settings.user.genders.female,
    male: Settings.user.genders.male,
    other: Settings.user.genders.other
  }
  enum role: {
    trainee: Settings.user.roles.trainee,
    supervisor: Settings.user.roles.supervisor,
    admin: Settings.user.roles.admin
  }

  # Associations
  has_many :user_courses, dependent: :destroy
  has_many :courses, through: :user_courses
  has_many :user_subjects, dependent: :destroy
  has_many :course_subjects, through: :user_subjects
  has_many :subjects, through: :course_subjects
  has_many :user_tasks, dependent: :destroy
  has_many :tasks, through: :user_tasks
  has_many :daily_reports, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :course_supervisors, dependent: :destroy
  has_many :supervised_courses, through: :course_supervisors, source: :course
  has_one_attached :image

  scope :recent, -> {order(created_at: :desc)}
  scope :sort_by_name, -> {order(:name)}
  scope :trainers, -> {where(role: :supervisor).count}
  scope :trainees, -> {where(role: :trainee).count}
  scope :supervised_by, (lambda do |user_id|
    joins(:supervised_courses).where(supervised_courses: {user_id:})
  end)
  scope :by_course, (lambda do |course_ids|
    return all if course_ids.blank?

    joins(:courses).where(courses: {id: course_ids})
  end)
  scope :filter_by_status, (lambda do |status|
    return all if status.blank?

    where(activated: status)
  end)
  scope :filter_by_name, (lambda do |search|
    return all if search.blank?

    where("LOWER(users.name) LIKE ?", "%#{search.downcase}%")
  end)

  before_save :downcase_email
  before_create :create_activation_digest

  validates :name, presence: true,
            length: {maximum: Settings.user.max_name_length}
  validates :email, presence: true,
            length: {maximum: Settings.user.max_email_length},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :birthday, presence: true, unless: :from_google_oauth
  validates :gender, presence: true, unless: :from_google_oauth
  validates :role, presence: true
  validate :birthday_within_valid_years,
           unless: -> {from_google_oauth || birthday.nil?}
  validates :password, presence: true,
            length: {minimum: Settings.user.min_password_length},
            allow_nil: true,
            if: :password_required?

  def self.digest string
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create string, cost:
  end

  def remember
    self.remember_token = User.new_token
    update_column :remember_digest, User.digest(remember_token)
  end

  def forget
    update_column :remember_digest, nil
  end

  def create_session
    self.session_token = User.new_token
    update_column :remember_digest, User.digest(session_token)
  end

  # Returns true if the given token matches the digest.
  def authenticated? attribute, token
    digest = send("#{attribute}_digest")
    return false unless digest

    BCrypt::Password.new(digest).is_password?(token)
  end

  # Activates an account.
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Creates password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns reset_digest: User.digest(reset_token),
                   reset_sent_at: Time.zone.now
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Sends password changed email.
  def send_password_changed_email
    UserMailer.password_changed(self).deliver_now
  end

  # Checks expiration of reset token.
  def password_reset_expired?
    reset_sent_at < PASSWORD_RESET_EXPIRATION.ago
  end
  class << self
    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  private

  def password_required?
    !from_google_oauth &&
      (password.present? || password_confirmation.present? || new_record?)
  end

  def birthday_within_valid_years
    return if birthday.nil?

    years = Settings.user.birthday_valid_years
    min_date = Time.zone.today - years.years
    return if birthday.between?(min_date, Time.zone.today)

    errors.add(:birthday, :birthday_invalid, years:)
  end

  def member_to_after_member_from
    return unless member_from && member_to

    return unless member_to < member_from

    errors.add(:member_to,
               :member_to_after_member_from)
  end

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    return if from_google_oauth

    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
