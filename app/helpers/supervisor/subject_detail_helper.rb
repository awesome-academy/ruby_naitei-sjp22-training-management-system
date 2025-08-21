module Supervisor::SubjectDetailHelper
  def user_tasks_done_subjects_admin user, tasks
    tasks.select {|task| task.user_id == user.id && task.done?}
  end

  def count_process_user_tasks tasks, user
    return Settings.trainee.subjects.default_progress if tasks.blank?

    if tasks.count > Settings.trainee.subjects.min_tasks
      completed_tasks = user_tasks_done_subjects_admin(user, tasks)
      ((completed_tasks.size.to_f / @subject_tasks_count) * Settings.percentage)
        .round
    else
      Settings.trainee.subjects.default_progress
    end
  end

  def file_type file_extension
    case file_extension.to_s.downcase.to_sym
    when :pdf
      "fas fa-file-pdf text-danger"
    when :doc, :docx
      "fas fa-file-word text-primary"
    when :xls, :xlsx
      "fas fa-file-excel text-success"
    when :ppt, :pptx
      "fas fa-file-powerpoint text-warning"
    when :jpg, :jpeg, :png, :gif
      "fas fa-file-image text-info"
    when :zip, :rar
      "fas fa-file-archive text-secondary"
    else
      "fas fa-file text-muted"
    end
  end
end
