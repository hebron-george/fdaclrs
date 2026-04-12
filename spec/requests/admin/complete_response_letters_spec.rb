require "rails_helper"

RSpec.describe "Admin::CompleteResponseLetters", type: :request do
  let(:admin) { User.create!(email: "admin@example.com", password: "password123", admin: true) }
  let(:regular_user) { User.create!(email: "user@example.com", password: "password123", admin: false) }
  let!(:letter) do
    CompleteResponseLetter.create!(
      file_name: "test.pdf",
      company_name: "Acme Pharma",
      letter_date: nil,
      approver_name: nil
    )
  end

  describe "GET /admin/letters" do
    context "as admin" do
      it "returns 200" do
        sign_in admin
        get admin_complete_response_letters_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as regular user" do
      it "redirects to root" do
        sign_in regular_user
        get admin_complete_response_letters_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not signed in" do
      it "redirects to sign-in" do
        get admin_complete_response_letters_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/letters/:id/edit" do
    it "returns 200 for admin" do
      sign_in admin
      get edit_admin_complete_response_letter_path(letter)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/letters/:id" do
    before { sign_in admin }

    it "updates the column and creates a correction log entry" do
      expect {
        patch admin_complete_response_letter_path(letter),
          params: {
            corrections: { letter_date: "2024-03-15" },
            notes:        { letter_date: "Found on page 1 of PDF" }
          }
      }.to change(LetterCorrection, :count).by(1)

      letter.reload
      expect(letter.letter_date).to eq(Date.new(2024, 3, 15))

      log = LetterCorrection.last
      expect(log.field_name).to eq("letter_date")
      expect(log.corrected_value).to eq("2024-03-15")
      expect(log.note).to eq("Found on page 1 of PDF")
      expect(log.user).to eq(admin)
    end

    it "does not create a log entry when the value is unchanged" do
      letter.update!(letter_date: Date.new(2024, 3, 15))

      expect {
        patch admin_complete_response_letter_path(letter),
          params: { corrections: { letter_date: "2024-03-15" } }
      }.not_to change(LetterCorrection, :count)
    end

    it "records the original API value in the log" do
      letter.update!(company_name: "Original Corp")

      patch admin_complete_response_letter_path(letter),
        params: { corrections: { company_name: "Corrected Corp" } }

      log = LetterCorrection.last
      expect(log.original_value).to eq("Original Corp")
      expect(log.corrected_value).to eq("Corrected Corp")
    end

    it "updates array fields from comma-separated input" do
      patch admin_complete_response_letter_path(letter),
        params: { corrections: { approver_center: "CDER, CBER" } }

      letter.reload
      expect(letter.approver_center).to contain_exactly("CDER", "CBER")
    end

    it "marks the letter as corrected after update" do
      patch admin_complete_response_letter_path(letter),
        params: { corrections: { approver_name: "Dr. Jane Smith" } }

      letter.reload
      expect(letter.corrected?(:approver_name)).to be true
    end
  end
end
