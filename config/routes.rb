
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
      end
    end

    namespace :supervisor do
      resources :daily_reports, only: %i(index show)
    end

    namespace :admin do
      resources :users
      resources :courses, controller: "/courses" do
        member do
          get :members, defaults: {scope: :admin}
          get :subjects, defaults: {scope: :admin}
          get :supervisors, defaults: {scope: :admin}
          delete :destroy_user_course, to: "/courses#destroy_user_course", defaults: {scope: :admin}
          delete :destroy_supervisor, to: "/courses#destroy_supervisor", defaults: {scope: :admin}
          delete :destroy_course_subject, to: "/courses#destroy_course_subject", defaults: {scope: :admin}
          post :finish_course_subject, to: "/courses#finish_course_subject", defaults: {scope: :admin}
        end
      end

      resources :subjects
      resources :categories
      resources :daily_reports, only: %i(index show)
    end
    
    namespace :supervisor do
      resources :courses, only: %i(show), controller: "/courses" do
        member do
          get :members
          get :subjects
          delete :destroy_user_course, to: "/courses#destroy_user_course"
          delete :destroy_course_subject, to: "/courses#destroy_course_subject"
          post :finish_course_subject, to: "/courses#finish_course_subject"
          delete :leave
        end
      end
    end

    namespace :admin do
      resources :dashboards 
      resources :courses, controller: "/courses" do
        member do
          get :members, defaults: {scope: :admin}
        end
      end
      resources :subjects
      resources :categories
      resources :daily_reports, only: %i(index show)
    end
  end
end
