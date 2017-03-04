module V1
  class PasswordsController < ApplicationController
    before_action :authenticate_request!, only: :update

    def update
      if @current_user && @current_user.authenticate(params[:current_password])
        if !params[:password].present? || params[:password].length < 8
          render json: {errors: ['Password must be a minimum of 8 characters']}, status: :unprocessable_entity
          return
        end

        if @current_user.reset_password!(params[:password], params[:password_confirmation])
          render json: {status: 'ok'}, status: :ok
        else
          render json: {errors: @current_user.errors.full_messages}, status: :unprocessable_entity
        end
      else
        render json: {errors: ['Invalid current password']}, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.permit(:current_password, :password, :password_confirmation)
    end

  end
end
