MiniOpeneras::Engine.routes.draw do

  resources :projects do
    resources :events
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
