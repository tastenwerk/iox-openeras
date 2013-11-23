MiniOpeneras::Engine.routes.draw do

  resources :projects do
    resources :events
  end

  resources :people
  resources :venues
  
  resources :labels do
    collection do
      get :projects
      get :people
    end
  end

end
