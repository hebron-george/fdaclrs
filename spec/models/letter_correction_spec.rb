require "rails_helper"

RSpec.describe LetterCorrection, type: :model do
  let(:user)   { User.create!(email: "admin@example.com", password: "password123", admin: true) }
  let(:letter) { CompleteResponseLetter.create!(file_name: "test.pdf", company_name: "Acme Corp") }

  describe "validations" do
    it "is valid with a known field and a corrected value" do
      correction = LetterCorrection.new(
        complete_response_letter: letter,
        user: user,
        field_name: "letter_date",
        corrected_value: "2024-01-15"
      )
      expect(correction).to be_valid
    end

    it "rejects unknown field names" do
      correction = LetterCorrection.new(
        complete_response_letter: letter,
        user: user,
        field_name: "nonexistent_field",
        corrected_value: "anything"
      )
      expect(correction).not_to be_valid
      expect(correction.errors[:field_name]).to be_present
    end

    it "requires a corrected_value" do
      correction = LetterCorrection.new(
        complete_response_letter: letter,
        user: user,
        field_name: "company_name",
        corrected_value: nil
      )
      expect(correction).not_to be_valid
    end
  end

  describe "CompleteResponseLetter#corrected?" do
    it "returns false when no corrections exist for the field" do
      expect(letter.corrected?(:letter_date)).to be false
    end

    it "returns true after a correction is logged for the field" do
      LetterCorrection.create!(
        complete_response_letter: letter,
        user: user,
        field_name: "letter_date",
        original_value: nil,
        corrected_value: "2024-01-15"
      )
      expect(letter.corrected?(:letter_date)).to be true
    end
  end

  describe "CompleteResponseLetter#api_original" do
    it "returns the original_value from the earliest correction log entry" do
      LetterCorrection.create!(
        complete_response_letter: letter,
        user: user,
        field_name: "company_name",
        original_value: "Old Name LLC",
        corrected_value: "Acme Corp"
      )
      expect(letter.api_original(:company_name)).to eq("Old Name LLC")
    end
  end
end
