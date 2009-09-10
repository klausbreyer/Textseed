class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://#{SITE_URL}/activate/#{user.activation_code}"
  
  end

  def inform(user, other, project)
    setup_email(user)
    @subject += "Welcome to Textseed"
    @body[:name] = user.login
    @body[:url] = "http://#{SITE_URL}/projects/#{project.id}"
    @body[:project] = project.subject
    @body[:projectdesc] = project.content
    @body[:invitor] = other.login
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://#{SITE_URL}/"
  end

  def forgot_password(user)
    setup_email(user)
    @subject    += 'You have requested to change your password'
    @body[:url]  = "http://#{SITE_URL}/reset_password/#{user.password_reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject    += 'Your password has been reset.'
  end
      
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "support@textseed.com"
    @subject     = "[Textseed] "
    @sent_on     = Time.now
    @body[:user] = user
  end
end
