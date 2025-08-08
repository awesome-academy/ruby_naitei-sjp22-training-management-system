module ApplicationHelper
  include Pagy::Frontend

  def full_title page_title = ""
    base_title = Settings.app.name || t("base_title")
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end

  def page_class
    controller.instance_variable_get(:@page_class)
  end

  def manager?
    return false unless current_user

    current_user.admin? || current_user.supervisor?
  end

  # Role helpers
  def admin_role?
    current_user&.admin?
  end

  def supervisor_role?
    current_user&.supervisor?
  end

  # Course path/url helpers determined by current user's role
  def course_link_url_for course
    if admin_role?
      admin_course_url(course)
    elsif supervisor_role?
      supervisor_course_url(course)
    else
      trainee_course_url(course)
    end
  end

  def course_members_path_for course
    if admin_role?
      members_admin_course_path(course)
    elsif supervisor_role?
      members_supervisor_course_path(course)
    else
      members_trainee_course_path(course)
    end
  end

  def course_subjects_path_for course
    if admin_role?
      subjects_admin_course_path(course)
    elsif supervisor_role?
      subjects_supervisor_course_path(course)
    else
      subjects_trainee_course_path(course)
    end
  end

  def destroy_user_course_path_for course, user_course_id:
    if admin_role?
      destroy_user_course_admin_course_path(course, user_course_id:)
    else
      destroy_user_course_supervisor_course_path(course, user_course_id:)
    end
  end

  def destroy_supervisor_path_for course, supervisor_id:
    destroy_supervisor_admin_course_path(course, supervisor_id:)
  end

  def finish_course_subject_path_for course, course_subject_id:
    if admin_role?
      finish_course_subject_admin_course_path(course, course_subject_id:)
    else
      finish_course_subject_supervisor_course_path(course, course_subject_id:)
    end
  end

  def destroy_course_subject_path_for course, course_subject_id:
    if admin_role?
      destroy_course_subject_admin_course_path(course, course_subject_id:)
    else
      destroy_course_subject_supervisor_course_path(course, course_subject_id:)
    end
  end

  def can_leave_course? course
    supervisor_role? &&
      course.supervisors.include?(current_user) &&
      course.supervisors.count > 1
  end

  def leave_course_path_for course
    leave_supervisor_course_path(course)
  end
end
