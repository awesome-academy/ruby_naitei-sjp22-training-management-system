# config/routes.rb

Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do
    root "static_pages#home"

    # --- Authentication & User Management ---
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :account_activations, only: :edit
    resources :password_resets, only: %i(new create edit update)
    resources :users, only: %i(show edit update)

    # --- Trainee Namespace ---
    namespace :trainee do
      resources :daily_reports, only: %i(index show new create edit update)

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
      resources :daily_reports
    end

    # --- Supervisor Namespace ---
    namespace :supervisor do
      resources :daily_reports, only: %i(index show)
      resources :subjects, only: %i(index show destroy new create)
      resources :tasks, only: %i(index show destroy new create)
      resources :categories, only: %i(index show destroy new create)
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
      resources :courses do
        member do
          get :members
          get :subjects
          get :supervisors
          delete :leave
        end
        resources :user_courses, only: [:destroy]
        resources :supervisors, only: [:destroy]
        resources :course_subjects, only: [:destroy] do
          post :finish, on: :member
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
        end
      end
      resources :subjects
      resources :categories
      resources :daily_reports, only: %i(index show)
    end
  end
end
