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
      end
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
