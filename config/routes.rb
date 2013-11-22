MiniOpeneras::Engine.routes.draw do

  resources :projects do
    collection do
      get :labels, to: 'labels#project_labels'
    end
  end

  resources :labels

end
