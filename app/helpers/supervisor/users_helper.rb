module Supervisor::UsersHelper
  def status_badge_class status
    case status.to_sym
    when :in_progress
      "bg-warning"
    when :finished
      "bg-success"
    when :not_started
      "bg-secondary"
    else
      "bg-info"
    end
  end

  def get_progress_user_course user_course
    return Settings.zero_value if user_course.nil?

    user_subjects = user_course.user_subjects.to_a
    user_subject_finished = user_subjects.count do |us|
      us.completed_at.present?
    end
    total_subjects = user_subjects.size

    return Settings.defaults.zero if total_subjects.zero?

    (user_subject_finished.to_f / total_subjects * Settings.percentage)
      .round(Settings.formats.decimal_places)
  end

  def user_gender_options
    [
      [t(".select_gender"), ""],
      [t("enums.user.gender.male"), :male],
      [t("enums.user.gender.female"), :female],
      [t("enums.user.gender.other"), :other]
    ]
  end

  def user_course_status_options
    [
      [t(".status_all"), ""],
      [t(".status_not_started"), :not_started],
      [t(".status_in_progress"), :in_progress],
      [t(".status_finished"), :finished]
    ]
  end

  def user_status_options
    [
      [t(".status_all"), nil],
      [t(".status_active"), true],
      [t(".status_inactive"), false]
    ]
  end
end
