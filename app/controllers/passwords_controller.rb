class PasswordsController < ApplicationController
  def forgot
    email = params[:email]

    if email.nil? || email.blank?
      return render json: {errors: ['Email cannot be blank']}, status: :unauthorized
    end

    user = User.find_by(email: email.downcase)

    if user.present? && user.confirmed_at?
      user.generate_password_token!
      PasswordMailer.forgot_password_confirmation(user).deliver_later
      render json: {status: 'ok'}, status: :ok
    else
      render json: {errors: ['Email address not found. Please check and try again.']}, status: :unauthorized
    end
  end

  def reset
    @token = params[:token].to_s

    if @token.nil? || @token.blank?
      return render json: {errors: ['Invalid link']}, status: :not_found
    else
      render template: "passwords/reset"
    end
  end

  def update
    @token = password_params[:token]
    user = User.find_by(reset_password_token: @token )

    if password_params[:password].length < 8
      flash[:danger] = 'Password must be a minimum of 8 characters.'
    else
      if user.present? && user.password_token_valid?
        if user.reset_password!(password_params[:password], password_params[:password_confirmation])
          flash[:success] = 'Password successfully reset.'
        else
          flash[:danger] = user.errors.full_messages.first
        end
      else
        flash[:danger] = 'The email link seems to be invalid. Try requesting for a new one.'
      end
    end
    render template: 'passwords/reset'
  end

  private

  def password_params
    params.require(:forgot_password).permit(:token, :password, :password_confirmation)
  end
end