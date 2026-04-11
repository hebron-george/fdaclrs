class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: :unsubscribe

  def index
    @subscriptions = current_user.subscriptions.order(created_at: :desc)
  end

  def create
    @subscription = current_user.subscriptions.build(subscription_params)

    if @subscription.save
      redirect_to subscriptions_path, notice: "Subscription \"#{@subscription.name}\" saved."
    else
      redirect_to complete_response_letters_path(filter_params),
                  alert: @subscription.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_user.subscriptions.find(params[:id]).destroy
    redirect_to subscriptions_path, notice: "Subscription removed."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def unsubscribe
    subscription = Subscription.find_by(unsubscribe_token: params[:token])
    if subscription
      subscription.deactivate!
      render plain: "You've been unsubscribed from \"#{subscription.name}\".", status: :ok
    else
      render plain: "Invalid or already used unsubscribe link.", status: :not_found
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:name, filters: {})
  end

  def filter_params
    params.permit(:q, :center, :company, :application_number, :date_from, :date_to)
  end
end
