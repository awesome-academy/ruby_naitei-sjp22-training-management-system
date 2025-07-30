module UsersHelper
  # Returns the Gravatar for the given user.
  def gravatar_for user, options = {size: Settings.ui.gravatar.default_size}
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  def gender_options
    User.genders.keys.map do |gender|
      [t("activerecord.attributes.user.genders.#{gender}"), gender]
    end
  end

  def current_user_admin?
    current_user&.admin?
  end

  def current_user? user
    user == current_user
  end
end
