module ApplicationHelper
  include Pagy::Frontend

  def full_title page_title = ""
    base_title = Settings.app.name || t("base_title")
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end

  def status_badge is_active
    case is_active
    when true
      text = t("common.active")
      css_class = "badge bg-success"
    else
      text = t("common.inactive")
      css_class = "badge bg-danger"
    end
    content_tag(:span, text, class: css_class)
  end

  def page_class
    controller.instance_variable_get(:@page_class)
  end

  def manager?
    return false unless current_user

    current_user.admin? || current_user.supervisor?
  end
end
