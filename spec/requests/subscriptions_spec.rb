require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { User.create!(email: "user@example.com", password: "password123") }

  describe "GET /subscriptions" do
    it "redirects unauthenticated users to sign in" do
      get subscriptions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns 200 for authenticated users" do
      sign_in user
      get subscriptions_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /subscriptions" do
    it "creates a subscription and redirects" do
      sign_in user
      expect {
        post subscriptions_path, params: {
          subscription: {
            name:    "Gene Therapy CBER",
            filters: { center: "Center for Biologics Evaluation and Research" }
          }
        }
      }.to change(Subscription, :count).by(1)

      expect(response).to redirect_to(subscriptions_path)
    end

    it "stores the filter params on the subscription" do
      sign_in user
      post subscriptions_path, params: {
        subscription: {
          name:    "My Search",
          filters: { q: "lentiviral", company: "gene cure" }
        }
      }
      sub = user.subscriptions.last
      expect(sub.filters["q"]).to eq("lentiviral")
      expect(sub.filters["company"]).to eq("gene cure")
    end
  end

  describe "DELETE /subscriptions/:id" do
    it "destroys the subscription" do
      sign_in user
      sub = Subscription.create!(user: user, name: "To Delete", filters: {})
      expect {
        delete subscription_path(sub)
      }.to change(Subscription, :count).by(-1)
      expect(response).to redirect_to(subscriptions_path)
    end

    it "cannot delete another user's subscription" do
      other_user = User.create!(email: "other@example.com", password: "password123")
      other_sub  = Subscription.create!(user: other_user, name: "Not Mine", filters: {})
      sign_in user
      expect {
        delete subscription_path(other_sub)
      }.not_to change(Subscription, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /unsubscribe/:token" do
    it "deactivates the subscription via token" do
      sub = Subscription.create!(user: user, name: "Email Sub", filters: {})
      get unsubscribe_path(sub.unsubscribe_token)
      expect(response).to have_http_status(:ok)
      expect(sub.reload.active).to be false
    end

    it "returns 404 for an invalid token" do
      get unsubscribe_path("invalidtoken")
      expect(response).to have_http_status(:not_found)
    end
  end
end
