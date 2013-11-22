MiniOpeneras::Engine.routes.draw do

  resources :projects do
    collection do
      get :labels, to: 'labels#project_labels'
    end
  end
  
  delete '/projects/labels/:id', to: 'labels#destroy'

  resources :labels

end
