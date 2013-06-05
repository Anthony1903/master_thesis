ProgManagementTool::Application.routes.draw do

  resources :pmodules,          :only => [:index]
  resources :cours_objects
  resources :ensemble_objects 
  resources :import_managers,   :only => [:index, :load_next, :load_files]
  resources :contrainte_objects
  resources :creators
  resources :compositors,       :only => [:index, :show]
  resources :diplome_objects
  
  match '/home', :to => 'pages#home'
  match '/composition', :to => 'pages#composition'
  match '/gestion', :to => 'pages#gestion'

  root :to => 'pages#home'

  match '/create_cours',  :to => 'cours_objects#new'
  match '/cours_objects/index',  :to => 'cours_objects#index'
  match '/cours_objects/restricted_index' => 'cours_objects#restricted_index'
  
  match '/create_ensemble',  :to => 'ensemble_objects#new'
  match '/ensemble_objects/index',  :to => 'ensemble_objects#index'
  match '/ensemble_objects/restricted_index' => 'ensemble_objects#restricted_index'
  match '/ensemble_objects/compaire' => 'ensemble_objects#compaire'

  match '/create_contrainte', :to => 'contrainte_objects#new'

  match '/import_managers/load_files' => 'import_managers#load_files'
  match '/import_managers/load_next' => 'import_managers#load_next'
  match '/import_managers/feedback' => 'import_managers#feedback'
  match '/import_managers/init_stack' => 'import_managers#init_stack'

  match '/creator/index' => 'creators#index'
  match '/creator/show' => 'creators#show'
  match '/creator/initialize_tree' => 'creators#initialize_tree'
  match '/creator/new_module' => 'creators#new_module'
  match '/creator/edit_module' => 'creators#edit_module'
  match '/creator/remove' => 'creators#remove'
  match '/creator/update' => 'creators#update'
  match '/creator/save_all' => 'creators#save_all'
  match '/creator/update_all' => 'creators#update_all'

  match '/compositor' => 'compositors#index'
  match '/compositor/show' => 'compositors#show'
  match '/compositor/check' => 'compositors#check'

  match '/diplome_objects/index' => 'diplome_objects#index'
  match '/create_diplome',  :to => 'diplome_objects#new'

  match '/contrainte_objects/index' => 'contrainte_objects#index'

        
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
