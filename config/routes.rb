MiniOpeneras::Engine.routes.draw do

  resources :projects do
    resources :events
    resources :files
    member do
      patch :translation
    end
  end

  resources :events do
    resources :prices do
      collection do
        post :make_template
        post :apply_project
      end
    end
  end

  resources :files
  resources :prices

  resources :people
  resources :venues

  resources :labels do
    collection do
      get :projects
      get :people
    end
  end

end
