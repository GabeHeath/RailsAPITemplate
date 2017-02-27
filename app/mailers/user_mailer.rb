class UserMailer < ApplicationMailer
  def sign_up_confirmation(user)
    @user = user
    @url  = "http://192.168.1.38:3000/users/confirm/#{user.confirmation_token}"
        mail(to: @user.email, subject: "Confirm your Registration!")
  end

  def email_update_confirmation(user)
    @user = user
    @url  = "http://192.168.1.38:3000/users/email_update/#{user.confirmation_token}"
    mail(to: @user.email, subject: "Confirm your new email!")
  end
end