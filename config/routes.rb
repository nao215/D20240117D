require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get '/health' => 'pages#health_check'
  get 'api-docs/v1/swagger.yaml' => 'swagger#yaml'

  namespace :api do
    resources :notes, only: [:create] do
      put ':id', to: 'notes#update', on: :collection
    end
    delete '/notes/:id', to: 'notes#destroy'
  end

  # ... other routes ...
end
