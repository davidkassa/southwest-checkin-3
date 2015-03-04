class UserMailer < ApplicationMailer
  def welcome(email)
    @email = email
    mail(to: @email, subject: "Welcome to #{ENV['SITE_NAME']}")
  end
end
