module V1
  class UsersController < ApplicationController
    before_action :authenticate_request!, only: :update
    before_action :validate_email_update, only: :update

    def create
      if user_params[:password] == user_params[:password_confirmation]
        user = User.new(user_params)

        if user.save
          UserMailer.sign_up_confirmation(user).deliver_later
          render json: {status: 'User created successfully'}, status: :created
        else
          render json: {errors: user.errors.full_messages}, status: :bad_request
        end
      else
        render json: {errors: ['Passwords do not match']}, status: :bad_request
      end
    end

    def login
      user = User.find_by(email: params[:email].to_s.downcase)

      if user && user.authenticate(params[:password])
        if user.confirmed_at?
          auth_token = JsonWebToken.encode({user_id: user.id})
          render json: {auth_token: auth_token}, status: :ok
        else
          UserMailer.sign_up_confirmation(user).deliver_later
          render json: {errors: ['Email not verified. Confirmation email has been resent.']}, status: :unauthorized
        end
      else
        render json: {errors: ['Invalid username / password']}, status: :unauthorized
      end
    end

    def update
      if @current_user.update_new_email!(@new_email)
        UserMailer.email_update_confirmation(@current_user).deliver_later
        render json: {status: ['Email Confirmation has been sent to your new Email']}, status: :ok
      else
        render json: {errors: @current_user.errors.full_messages}, status: :bad_request
      end
    end

    private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :password_confirmation)
    end

    def validate_email_update
      @new_email = params[:email].to_s.downcase

      if @new_email.blank?
        return render json: {errors: ['Email cannot be blank']}, status: :bad_request
      end

      if @new_email == @current_user.email
        return render json: {errors: ['Current Email and New email cannot be the same']}, status: :bad_request
      end

      if User.email_used?(@new_email)
        return render json: {errors: ['Email is already in use']}, status: :unprocessable_entity
      end
    end
  end
end
