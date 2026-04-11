require "rails_helper"

RSpec.describe Subscription, type: :model do
  def build_letter(attrs = {})
    defaults = {
      file_name:           "letter_#{SecureRandom.hex(4)}.pdf",
      application_numbers: ["BLA125012"],
      letter_type:         "COMPLETE RESPONSE",
      letter_date:         Date.new(2023, 6, 15),
      company_name:        "Example Therapeutics",
      approver_center:     ["Center for Biologics Evaluation and Research"],
      approver_name:       "Dr. Jane Smith",
      text:                "gene therapy lentiviral vector"
    }
    CompleteResponseLetter.create!(defaults.merge(attrs))
  end

  def build_user
    User.create!(email: "test_#{SecureRandom.hex(4)}@example.com", password: "password123")
  end

  def build_subscription(filters: {}, **attrs)
    Subscription.create!(
      user:    build_user,
      name:    "Test Sub",
      filters: filters,
      **attrs
    )
  end

  describe "validations" do
    it "requires a name" do
      sub = Subscription.new(user: build_user, name: "", filters: {})
      expect(sub).not_to be_valid
      expect(sub.errors[:name]).to be_present
    end

    it "generates a unique unsubscribe_token before create" do
      sub = build_subscription
      expect(sub.unsubscribe_token).to be_present
    end
  end

  describe "#matches?" do
    let(:letter) { build_letter }

    it "matches when filters is empty (catches everything)" do
      sub = build_subscription(filters: {})
      expect(sub.matches?(letter)).to be true
    end

    context "full-text query filter" do
      it "matches when query term is found in letter text" do
        sub = build_subscription(filters: { "q" => "lentiviral" })
        expect(sub.matches?(letter)).to be true
      end

      it "does not match when query term is absent" do
        sub = build_subscription(filters: { "q" => "zzznomatch" })
        expect(sub.matches?(letter)).to be false
      end

      it "matches company_name" do
        sub = build_subscription(filters: { "q" => "Example Therapeutics" })
        expect(sub.matches?(letter)).to be true
      end
    end

    context "center filter" do
      it "matches when center is in approver_center array" do
        sub = build_subscription(filters: { "center" => "Center for Biologics Evaluation and Research" })
        expect(sub.matches?(letter)).to be true
      end

      it "does not match when center differs" do
        sub = build_subscription(filters: { "center" => "Center for Drug Evaluation and Research" })
        expect(sub.matches?(letter)).to be false
      end
    end

    context "company filter" do
      it "matches on partial, case-insensitive company name" do
        sub = build_subscription(filters: { "company" => "example" })
        expect(sub.matches?(letter)).to be true
      end

      it "does not match a different company" do
        sub = build_subscription(filters: { "company" => "Pharma Corp" })
        expect(sub.matches?(letter)).to be false
      end
    end

    context "application number filter" do
      it "matches a letter containing the application number" do
        sub = build_subscription(filters: { "application_number" => "BLA125012" })
        expect(sub.matches?(letter)).to be true
      end

      it "does not match when application number is absent" do
        sub = build_subscription(filters: { "application_number" => "NDA999999" })
        expect(sub.matches?(letter)).to be false
      end
    end

    context "date range filter" do
      it "matches when letter date falls within range" do
        sub = build_subscription(filters: { "date_from" => "2023-01-01", "date_to" => "2023-12-31" })
        expect(sub.matches?(letter)).to be true
      end

      it "does not match when letter date is before date_from" do
        sub = build_subscription(filters: { "date_from" => "2024-01-01" })
        expect(sub.matches?(letter)).to be false
      end

      it "does not match when letter date is after date_to" do
        sub = build_subscription(filters: { "date_to" => "2022-12-31" })
        expect(sub.matches?(letter)).to be false
      end

      it "matches with only date_from set" do
        sub = build_subscription(filters: { "date_from" => "2023-01-01" })
        expect(sub.matches?(letter)).to be true
      end
    end

    context "combined filters" do
      it "requires ALL filters to match (AND logic)" do
        sub = build_subscription(filters: {
          "q"       => "lentiviral",
          "company" => "example",
          "center"  => "Center for Drug Evaluation and Research"  # won't match
        })
        expect(sub.matches?(letter)).to be false
      end

      it "matches when all filters are satisfied" do
        sub = build_subscription(filters: {
          "q"       => "lentiviral",
          "company" => "example",
          "center"  => "Center for Biologics Evaluation and Research"
        })
        expect(sub.matches?(letter)).to be true
      end
    end
  end

  describe "#deactivate!" do
    it "sets active to false" do
      sub = build_subscription
      sub.deactivate!
      expect(sub.reload.active).to be false
    end
  end
end
