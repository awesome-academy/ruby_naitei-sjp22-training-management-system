Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do
    get "static_pages/home"
    get "static_pages/help"
    get "static_pages/contact"
    get "microposts/index"

    resources :microposts, only: [:index]

    root "static_pages#home"

    get "/signup", to: "users#new"
    post "/signup", to: "users#create"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :users
    resources :account_activations, only: :edit
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
