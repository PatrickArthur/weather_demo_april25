Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :weathers, only: [:index, :create, :new, :destroy, :edit, :update]

  # Defines the root path route ("/")
  root "weathers#index"
end
