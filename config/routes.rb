
Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do
    root "static_pages#home"

    get "/help", to: "static_pages#help"
    get "/contact", to: "static_pages#contact"

    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :account_activations, only: :edit
    resources :password_resets, only: %i(new create edit update)
    resources :users, only: %i(show edit update new create)

    namespace :trainee do
      resources :daily_reports
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

    namespace :supervisor do
      resources :daily_reports, only: %i(index show)
    end

    namespace :admin do
      resources :users
      resources :courses do
        member do
          get :members
        end
      end

      resources :subjects
      resources :categories
      resources :daily_reports, only: %i(index show)
    end
    
    namespace :admin do
      resources :dashboards 
      resources :courses do
        member do
          get :members
        end
      end
      resources :subjects
      resources :categories
      resources :daily_reports, only: %i(index show)
    end
  end
end
