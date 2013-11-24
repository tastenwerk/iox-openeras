MiniOpeneras::Engine.routes.draw do

  resources :projects do
    resources :events
    member do
      patch :translation
    end
  end

  resources :events
  resources :people
  resources :venues

  resources :labels do
    collection do
      get :projects
      get :people
    end
  end

end
