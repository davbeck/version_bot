Rails.application.routes.draw do
  api_version(module: "V1", defaults: {format: :json}, path: {value: "v1"}) do
    resource :versions, only: [:show, :update, :create] do
    end
  end
end
