require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) do
    User.new(
      name: "Example User",
      email: "user@example.com",
      birthday: Date.new(2000, 1, 1),
      gender: "male",
      role: "trainee",
      password: "password",
      password_confirmation: "password"
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "requires name" do
      user.name = nil
      expect(user).not_to be_valid
      # SỬA LỖI 1: Cập nhật thông báo lỗi theo locale tiếng Việt
      expect(user.errors[:name]).to include("không thể để trống")
    end

    it "requires email" do
      user.email = nil
      expect(user).not_to be_valid
    end

    it "rejects invalid email format" do
      user.email = "invalid_email"
      expect(user).not_to be_valid
    end

    it "rejects duplicate email (case insensitive)" do
      user.save!
      dup = user.dup
      dup.email = user.email.upcase
      expect(dup).not_to be_valid
    end

    it "requires birthday unless from_google_oauth" do
      user.birthday = nil
      expect(user).not_to be_valid

      user.from_google_oauth = true
      expect(user).to be_valid
    end

    it "requires gender unless from_google_oauth" do
      user.gender = nil
      expect(user).not_to be_valid

      user.from_google_oauth = true
      expect(user).to be_valid
    end

    it "requires password with minimum length" do
      user.password = user.password_confirmation = "123"
      expect(user).not_to be_valid
    end
  end

  describe "associations" do
    it { should have_many(:user_courses).dependent(:destroy) }
    it { should have_many(:courses).through(:user_courses) }
    it { should have_many(:user_subjects).dependent(:destroy) }
    it {should have_many(:course_subjects).through(:user_subjects)}
    it { should have_many(:subjects).through(:course_subjects) }
    it { should have_many(:user_tasks).dependent(:destroy) }
    it { should have_many(:tasks).through(:user_tasks) }
    it { should have_many(:daily_reports).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:course_supervisors).dependent(:destroy) }
    it { should have_many(:supervised_courses).through(:course_supervisors) }
    it { should have_one_attached(:image) }
  end

  describe "enums" do
    it { should define_enum_for(:gender).with_values(female: Settings.user.genders.female,
                                                     male: Settings.user.genders.male,
                                                     other: Settings.user.genders.other) }
    it { should define_enum_for(:role).with_values(trainee: Settings.user.roles.trainee,
                                                   supervisor: Settings.user.roles.supervisor,
                                                   admin: Settings.user.roles.admin) }
  end

  # ... (phần còn lại của file giữ nguyên) ...
  describe "scopes" do
    let!(:user1) { create(:user, name: "Alice", role: :trainee, activated: true) }
    let!(:user2) { create(:user, name: "Bob", role: :supervisor, activated: false) }

    it "sorts recent" do
      expect(User.recent.first).to eq(user2)
    end

    it "sorts by name" do
      expect(User.sort_by_name).to eq([user1, user2])
    end

    it "filters by name" do
      expect(User.filter_by_name("ali")).to include(user1)
      expect(User.filter_by_name("ali")).not_to include(user2)
    end

    it "filters by status" do
      expect(User.filter_by_status(true)).to include(user1)
      expect(User.filter_by_status(false)).to include(user2)
    end
  end

  describe "callbacks" do
    it "downcases email before save" do
      user.email = "USER@EXAMPLE.COM"
      user.save!
      expect(user.reload.email).to eq("user@example.com")
    end

    it "creates activation digest before create (unless from_google_oauth)" do
      user.save!
      expect(user.activation_digest).not_to be_nil
    end

    it "skips activation digest if from_google_oauth" do
      user.from_google_oauth = true
      user.save!
      expect(user.activation_digest).to be_nil
    end
  end

  describe "instance methods" do
    before { user.save! }

    it "generates digest and authenticates" do
      token = User.new_token
      digest = User.digest(token)
      expect(BCrypt::Password.new(digest).is_password?(token)).to be true
    end

    it "remembers and forgets user" do
      user.remember
      expect(user.remember_digest).not_to be_nil
      user.forget
      expect(user.remember_digest).to be_nil
    end

    it "creates session" do
      user.create_session
      expect(user.remember_digest).not_to be_nil
    end

    it "activates user" do
      user.activate
      expect(user.activated).to be true
    end

    it "checks reset token expiration" do
      user.create_reset_digest
      expect(user.password_reset_expired?).to be false

      user.update!(reset_sent_at: 3.hours.ago)
      expect(user.password_reset_expired?).to be true
    end
  end

  describe "class methods" do
    it "generates new token" do
      expect(User.new_token).to be_a(String)
    end
  end
end
