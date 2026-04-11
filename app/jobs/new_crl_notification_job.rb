class NewCrlNotificationJob
  include Sidekiq::Job

  def perform(new_file_names)
    return if new_file_names.blank?

    new_letters = CompleteResponseLetter.where(file_name: new_file_names)
    active_subscriptions = Subscription.active.includes(:user)

    new_letters.each do |letter|
      active_subscriptions.each do |subscription|
        next unless subscription.matches?(letter)

        SubscriptionMailer.new_crl_match(subscription.id, letter.id).deliver_later
      end
    end
  end
end
