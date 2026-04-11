# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer_mailer
class SubscriptionMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/subscription_mailer_mailer/new_crl_match
  def new_crl_match
    SubscriptionMailer.new_crl_match
  end

end
