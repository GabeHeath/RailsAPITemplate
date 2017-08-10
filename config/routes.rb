Rails.application.routes.draw do
  scope module: :v1, constraints: ApiConstraint.new(version: 1) do
    resources :users, only: [:create] do
      collection do
        post 'auth'
        post 'auth/refresh', to: 'users#refresh'
        post 'auth/revoke', to: 'users#revoke'
        patch 'email/update', to: 'users#update_email'
      end
    end

    patch 'password/update', to: 'passwords#update'
  end

  resources :builds, only: :show

  get '/users/confirm/:token', to: 'users#confirm'
  get '/users/email_update/:token', to: 'users#email_update'

  patch 'password/forgot', to: 'passwords#forgot'
  get 'password/reset/:token', to: 'passwords#reset'
  post 'password/reset', to: 'passwords#update'

end