# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize user
    return if user.blank?

    case user.role.to_sym
    when :trainee
      trainee_permissions(user)
    when :supervisor
      supervisor_permissions(user)
    when :admin
      admin_permissions(user)
    end
  end

  private

  # ---------------- Trainee ----------------
  def trainee_permissions user
    can :manage, DailyReport, user_id: user.id

    can %i(read members subjects), Course, user_courses: {user_id: user.id}

    can :read, Subject, courses: {user_courses: {user_id: user.id}}

    can :update, UserSubject, user_id: user.id

    can %i(update_document update_status update_spent_time destroy_document),
        UserTask, user_id: user.id
  end

  # ---------------- Supervisor ----------------
  def supervisor_permissions user
    # Daily reports (read only)
    can :read, DailyReport, course_id: user.supervised_course_ids

    # Full CRUD on Subjects, Tasks, Categories
    can :manage, Subject
    can :manage, Task
    can :manage, Category

    # Manage users (but not destroy)
    can %i(index show update update_status update_user_course_status
    delete_user_course bulk_deactivate),
        User

    # Courses
    can %i(index show new create edit update members subjects
    supervisors search_members leave add_subject),
        Course, supervisors: {id: user.id}

    can :manage, UserCourse, course_id: user.supervised_course_ids

    can :manage, CourseSupervisor, course_id: user.supervised_course_ids

    # SubjectDetails (nested inside course)
    can %i(show create_task update_task update_score create_comment
    destroy_comment update_comment finish destroy),
        CourseSubject, course_id: user.supervised_course_ids

    # Extra subject actions
    can :destroy_tasks, Subject, courses: {id: user.supervised_course_ids}
  end

  # ---------------- Admin ----------------
  def admin_permissions _user
    can :manage, :all
    cannot :destroy, DailyReport
    cannot :update, DailyReport
  end
end
