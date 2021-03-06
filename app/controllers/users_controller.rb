class UsersController < ApplicationController
  def confirm
    token = params[:token].to_s

    user = User.find_by(confirmation_token: token)

    if user.present?
      user.mark_as_confirmed!
      render json: {status: 'User confirmed successfully'}, status: :ok
    else
      render json: {errors: ['Invalid token']}, status: :bad_request
    end
  end

  def email_update
    token = params[:token].to_s
    user = User.find_by(confirmation_token: token)

    if !user || !user.confirmation_token_valid?
      render json: {errors: ['The email link seems to be invalid / expired. Try requesting for a new one.']}, status: :bad_request
    else
      user.confirm_new_email!
      render json: {status: 'Email updated successfully'}, status: :ok
    end
  end
end