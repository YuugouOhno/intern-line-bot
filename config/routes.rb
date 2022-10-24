Rails.application.routes.draw do
  resources :widgets

  root 'welcome#index'

  # for LINE webhook
  post '/callback' => 'webhook#callback'

  get '/create' => 'webhook#create'
end
