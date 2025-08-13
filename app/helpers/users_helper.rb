module UsersHelper
  def gravatar_for object, options = {size: Settings.ui.gravatar.default_size}
    email_source = if object.respond_to?(:email)
                     object.email.downcase
                   else
                     object.name.downcase
                   end
    gravatar_id = Digest::MD5.hexdigest(email_source)
    size = options[:size]
    alt_text = object.respond_to?(:name) ? object.name : Settings.avatar
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: alt_text, class: "gravatar")
  end

  def gender_options
    User.genders.keys.map do |gender|
      [t("activerecord.attributes.user.genders.#{gender}"), gender]
    end
  end

  def status_filter_options
    [
      [t("admin.users.index.all_statuses"), ""],
      [t("common.active"), true],
      [t("common.inactive"), false]
    ]
  end

  def search_type_options
    [
      [t("admin.users.index.name_search_type"), "name"]
    ]
  end

  def current_user? user
    user == current_user
  end
end
