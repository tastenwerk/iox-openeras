MiniOpeneras::Engine.routes.draw do

  resources :projects do
    resources :events
    resources :files
    resources :people
    resources :project_people
    member do
      patch :translation
      patch :publish
      post :restore
      patch :apply_file_settings
    end
    collection do
      get :ejson
    end
  end

  resources :project_people do
    collection do
      post :reorder
    end
  end

  resources :events do
    resources :prices do
      collection do
        post :make_template
        post :apply_project
        post :apply_systemwide
      end
    end
  end

  resources :files do
    member do
      post :coords
    end
    collection do
      post :reorder
    end
  end
  
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
