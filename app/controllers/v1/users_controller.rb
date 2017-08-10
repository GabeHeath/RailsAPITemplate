module V1
  class UsersController < ApplicationController
    before_action :authenticate_request!, only: :update
    before_action :validate_email_update, only: :update

    def create
      unless user_params[:password] == user_params[:password_confirmation]
        return render json: {errors: ['Passwords do not match']}, status: :bad_request
      end

      user = User.new(user_params)

      if user.save
        UserMailer.sign_up_confirmation(user).deliver_later
        render json: {status: 'User created successfully'}, status: :created
      else
        render json: {errors: user.errors.full_messages}, status: :bad_request
      end
    end

    def auth
      # [login, password]
      login_credentials = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
      user = User.find_by(email: login_credentials[0].to_s.downcase)

      if user && user.authenticate(login_credentials[1])
        if user.confirmed_at? || user.confirmation_sent_at > 3.hours.ago # Give the user a grace period to confirm their email. This allows them to log in immediately after registering
          refresh_token  = RefreshToken.new(user_id: user.id, value: JsonWebToken.encode({user_id: user.id}, 'refresh'))
          if refresh_token.save
            access_token = JsonWebToken.encode({user_id: user.id}, 'access')
            render json: {
                       tokens: {
                           access: access_token,
                           refresh: refresh_token.value
                       }
                   }, status: :ok
            end
        else
          UserMailer.sign_up_confirmation(user).deliver_later
          render json: {errors: ['Email not verified. Confirmation email has been resent.']}, status: :unauthorized
        end
      else
        render json: {errors: ['Invalid username / password']}, status: :unauthorized
      end
    end

    def refresh
      token = token_params[:refresh]
      refreshed_tokens = RefreshToken.validate_and_refresh(token)
      if refreshed_tokens
        render json: {
            tokens: {
                access: refreshed_tokens[:access],
                refresh: refreshed_tokens[:refresh]
            }
        }, status: :ok
      else
        render json: {errors: ['Invalid Request']}, status: :unauthorized
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

    def token_params
      params.require(:token).permit(:refresh)
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
