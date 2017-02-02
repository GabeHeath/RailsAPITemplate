Rails.application.routes.draw do
  scope module: :v1, constraints: ApiConstraint.new(version: 1) do
    resources :users, only: [:create, :update] do
      collection do
        post 'confirm'
        post 'login'
        post 'email_update'
        post 'status'
      end
    end

    post 'password/forgot', to: 'password#forgot'
    post 'password/reset', to: 'password#reset'
    put 'password/update', to: 'password#update'
  end

  resources :builds, only: :show
end
