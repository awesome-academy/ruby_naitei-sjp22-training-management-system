# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, only: [:sessions]

  scope "(:locale)", locale: /vi|en/ do
    root "static_pages#home"

    # resources :account_activations, only: :edit
    # resources :password_resets, only: %i(new create edit update)
    resources :users, only: %i(show edit update)

    # Subject search API (accessible to all authenticated users)
    resources :subjects, only: :index

    # --- Trainee Namespace ---
    namespace :trainee do
      resources :daily_reports, only: %i(index show new create edit update destroy)

      resources :courses, only: %i(show) do
        member do
          get :members
          get :subjects
        end
        resources :subjects, only: %i(show)
      end

      resources :user_subjects, only: %i(update)
      resources :user_tasks, only: [] do
        member do
          patch :update_document, path: "document"
          patch :update_status, path: "status"
          patch :update_spent_time, path: "spent_time"
          delete :destroy_document, path: "document"
        end
      end
    end

    # --- Supervisor Namespace ---
    namespace :supervisor do
      resources :daily_reports, only: %i(index show)
      resources :subjects
      resources :tasks
      resources :categories
      resources :users, only: %i(index show update) do
        member do
          patch :update_status
          patch :update_user_course_status, path: "user_course_status"
          delete :delete_user_course, path: "user_course"
        end
        collection do
          patch :bulk_deactivate
        end
      end
      resources :courses, only: %i(index show new create edit update) do
        resources :subject_details, only: %i(show) do
          member do
            post :create_task
            patch :update_task
            patch :update_score
            post :create_comment
            delete :destroy_comment
            patch :update_comment
          end
        end
        member do
          get :members
          get :subjects
          get :supervisors
          get :search_members
          delete :leave
          post :add_subject
        end
        resources :user_courses, only: %i(create destroy)
        resources :supervisors, only: %i(create destroy)
        resources :course_subjects, only: [:destroy] do
          post :finish, on: :member
        end
      end
      resources :subjects do
        member do
          delete :destroy_tasks
        end
      end
    end

    # --- Admin Namespace ---
    namespace :admin do
      resources :dashboards
      resources :users, only: %i(index show update) do
        member do
          patch :update_status
          delete :delete_user_course, path: "user_course"
        end
        collection do
          patch :bulk_deactivate
          get :new_supervisor
          patch :add_role_supervisor
        end
      end
      resources :admin_users, only: %i(index new create show destroy) do
        member do
          patch :activate
          patch :deactivate
        end
        collection do
          post :promote
        end
      end

      resources :daily_reports, only: %i(index show)
    end
  end
end
