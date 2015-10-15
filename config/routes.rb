Rails.application.routes.draw do
  root to: redirect('https://github.com/davbeck/version_bot')
  
  api_version(module: "V1", defaults: {format: :json}, path: {value: "v1"}) do
    resource :versions, only: [:show, :update, :create] do
    end
  end
end
