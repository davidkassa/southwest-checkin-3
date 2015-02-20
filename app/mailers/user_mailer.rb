class UserMailer < MandrillMailer
  def self.welcome_email(user)
    mail(to: user.email,
         subject: "Welcome to #{ENV['SITE_NAME']}",
         template_name: 'Welcome')
  end
end
