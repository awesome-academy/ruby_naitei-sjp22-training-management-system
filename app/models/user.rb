class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :validatable, :confirmable, :recoverable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  # Constants
  PERMITTED_ATTRIBUTES = %i(name email password password_confirmation birthday
gender).freeze
  PERMITTED_UPDATE_ATTRIBUTES = %i(name birthday gender).freeze
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

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
  has_many :subjects, through: :user_subjects
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

  validates :name, presence: true,
            length: {maximum: Settings.user.max_name_length}
  validates :email, presence: true,
            length: {maximum: Settings.user.max_email_length},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :birthday, presence: true, unless: -> {provider.present?}
  validates :gender, presence: true, unless: -> {provider.present?}
  validates :role, presence: true
  validate :birthday_within_valid_years
  validates :password, presence: true,
            length: {minimum: Settings.user.min_password_length},
            allow_nil: true,
            if: :password_required?

  class << self
    def from_omniauth auth
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        generate_user_password(user)
        user.name = auth.info.name
        user.confirmed_at = Time.zone.now
        user_avatar_google(auth, user)
      end
    end

    def generate_user_password user
      user.password = Devise.friendly_token
                            .first(Settings.user.max_password_length)
    end

    def user_avatar_google auth, user
      return if auth.info.image.blank?

      res = Faraday.get(auth.info.image)
      user.image.attach(
        io: StringIO.new(res.body),
        filename: "#{user.name.parameterize}_avatar.jpg",
        content_type: res.headers["content-type"] || "image/jpeg"
      )
    end
  end

  private

  def user_avatar_google auth, user
    return if auth.info.image.blank?

    user.image.attach(io: Faraday.get(auth.info.image).body,
                      filename: "#{user.name}_avatar.jpg")
  end

  def birthday_within_valid_years
    return if birthday.nil?

    years = Settings.user.birthday_valid_years
    min_date = Time.zone.today - years.years
    return if birthday.between?(min_date, Time.zone.today)

    errors.add(:birthday, :birthday_invalid, years:)
  end

  def downcase_email
    email.downcase!
  end
end
