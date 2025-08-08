module Trainee::SubjectsHelper
  def count_user_tasks_done user, tasks
    UserTask.by_user(user)&.tasks_done&.by_task(tasks)
  end

  def count_process_tasks tasks
    if tasks.count > Settings.trainee.subjects.min_tasks
      ((count_user_tasks_done(
        current_user, tasks
      ).size.to_f / tasks.count) * Settings.percentage).round
    else
      Settings.trainee.subjects.default_progress
    end
  end

  def count_score_subject user_subject
    (user_subject.score.to_f / Settings.user_subject.max_score) *
      Settings.percentage
  end

  def get_unfinished_tasks user_subject
    current_user.user_tasks.by_user_subject(user_subject).not_done
  end

  def get_status_user_subject actual_end_date, plan_end_date
    return if actual_end_date.blank?

    if actual_end_date == plan_end_date
      Settings.user_subject.status.finished_ontime
    elsif actual_end_date > plan_end_date
      Settings.user_subject.status.finished_but_overdue
    elsif actual_end_date < plan_end_date
      Settings.user_subject.status.finished_early
    end
  end
end
