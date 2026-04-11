require "rails_helper"

RSpec.describe SubscriptionMailer, type: :mailer do
  let(:user)   { User.create!(email: "user@example.com", password: "password123") }
  let(:letter) do
    CompleteResponseLetter.create!(
      file_name:           "test_crl.pdf",
      company_name:        "Gene Cure Inc",
      application_numbers: ["BLA 761373"],
      letter_date:         Date.new(2023, 6, 15),
      approver_center:     ["Center for Biologics Evaluation and Research"],
      approver_name:       "Dr. Jane Smith",
      letter_type:         "COMPLETE RESPONSE",
      text:                "gene therapy lentiviral"
    )
  end
  let(:subscription) { Subscription.create!(user: user, name: "Gene Therapy CBER", filters: { "center" => "Center for Biologics Evaluation and Research" }) }

  describe "#new_crl_match" do
    let(:mail) { SubscriptionMailer.new_crl_match(subscription.id, letter.id) }

    it "sends to the subscriber's email" do
      expect(mail.to).to eq(["user@example.com"])
    end

    it "includes the company name in the subject" do
      expect(mail.subject).to include("Gene Cure Inc")
    end

    it "includes the application number in the subject" do
      expect(mail.subject).to include("BLA 761373")
    end

    it "includes the subscription name in the body" do
      expect(mail.body.encoded).to include("Gene Therapy CBER")
    end

    it "includes a link to the letter" do
      expect(mail.body.encoded).to include(complete_response_letter_url(letter))
    end

    it "includes an unsubscribe link" do
      expect(mail.body.encoded).to include(unsubscribe_url(subscription.unsubscribe_token))
    end
  end
end
