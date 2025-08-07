Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do

    root "static_pages#home"
    get "static_pages/home"
    get "static_pages/help"
    get "static_pages/contact"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"

    resources :account_activations, only: :edit
    resources :password_resets, only: %i(new create edit update)
    resources :users, only: %i(show edit update)

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

    namespace :admin do
      root "dashboards#show", as: :dashboard

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
  end
end
