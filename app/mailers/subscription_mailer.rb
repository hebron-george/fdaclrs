class SubscriptionMailer < ApplicationMailer
  # Sends a notification email when a newly synced CRL matches a subscription.
  #
  # @param subscription_id [Integer]
  # @param letter_id [Integer]
  def new_crl_match(subscription_id, letter_id)
    @subscription    = Subscription.find(subscription_id)
    @letter          = CompleteResponseLetter.find(letter_id)
    @user            = @subscription.user
    @unsubscribe_url = unsubscribe_url(@subscription.unsubscribe_token)

    mail(
      to:      @user.email,
      subject: "New FDA CRL match: #{@letter.company_name} — #{@letter.application_numbers.first}"
    )
  end
end
