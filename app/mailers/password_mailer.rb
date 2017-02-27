class PasswordMailer < ApplicationMailer
  def forgot_password_confirmation(user)
    @user = user
    @url  = "http://192.168.1.38:3000/password/reset/#{user.reset_password_token}"
    mail(to: @user.email, subject: "Account Password Reset")
  end
end