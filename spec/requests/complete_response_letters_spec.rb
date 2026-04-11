require "rails_helper"

RSpec.describe "CompleteResponseLetters", type: :request do
  def create_letter(attrs = {})
    defaults = {
      file_name:           "letter_#{SecureRandom.hex(4)}.pdf",
      application_numbers: ["BLA125012"],
      letter_type:         "COMPLETE RESPONSE",
      letter_date:         Date.new(2023, 6, 15),
      company_name:        "Example Therapeutics",
      approver_center:     ["Center for Biologics Evaluation and Research"],
      approver_name:       "Dr. Jane Smith",
      text:                "We cannot approve this application in its present form."
    }
    CompleteResponseLetter.create!(defaults.merge(attrs))
  end

  describe "GET /complete_response_letters" do
    it "returns 200" do
      get complete_response_letters_path
      expect(response).to have_http_status(:ok)
    end

    it "defaults to filtering by CBER" do
      create_letter(company_name: "CBER Therapeutics",  approver_center: ["Center for Biologics Evaluation and Research"])
      create_letter(company_name: "CDER Pharmaceuticals", approver_center: ["Center for Drug Evaluation and Research"])

      get complete_response_letters_path
      expect(response.body).to include("CBER Therapeutics")
      expect(response.body).not_to include("CDER Pharmaceuticals")
    end

    it "shows all centers when center param is blank" do
      create_letter(company_name: "CBER Therapeutics",  approver_center: ["Center for Biologics Evaluation and Research"])
      create_letter(company_name: "CDER Pharmaceuticals", approver_center: ["Center for Drug Evaluation and Research"])

      get complete_response_letters_path, params: { center: "" }
      expect(response.body).to include("CBER Therapeutics")
      expect(response.body).to include("CDER Pharmaceuticals")
    end

    it "filters by company name" do
      create_letter(company_name: "BlueBird Bio",  approver_center: ["Center for Biologics Evaluation and Research"])
      create_letter(company_name: "Pharma Corp", approver_center: ["Center for Biologics Evaluation and Research"])

      get complete_response_letters_path, params: { company: "bluebird", center: "" }
      expect(response.body).to include("BlueBird Bio")
      expect(response.body).not_to include("Pharma Corp")
    end

    it "filters by application number" do
      create_letter(company_name: "Gene Cure Inc",   application_numbers: ["BLA 761373", "BLA 761425"])
      create_letter(company_name: "Small Mol Corp",  application_numbers: ["NDA999999"])

      get complete_response_letters_path, params: { application_number: "BLA 761373", center: "" }
      expect(response.body).to include("Gene Cure Inc")
      expect(response.body).not_to include("Small Mol Corp")
    end

    it "filters by date range" do
      create_letter(company_name: "Old Co",    letter_date: Date.new(2021, 1, 1))
      create_letter(company_name: "Recent Co", letter_date: Date.new(2023, 6, 15))

      get complete_response_letters_path, params: { date_from: "2023-01-01", date_to: "2023-12-31", center: "" }
      expect(response.body).to include("Recent Co")
      expect(response.body).not_to include("Old Co")
    end

    it "shows empty state when no results" do
      get complete_response_letters_path, params: { q: "zzznomatch", center: "" }
      expect(response.body).to include("No letters found")
    end
  end

  describe "GET /complete_response_letters/:id" do
    it "returns 200 and shows letter details" do
      letter = create_letter(
        company_name:        "Gene Cure Inc",
        application_numbers: ["BLA 761373", "BLA 761425"],
        approver_name:       "Dr. Jane Smith"
      )

      get complete_response_letter_path(letter)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Gene Cure Inc")
      expect(response.body).to include("BLA 761373")
      expect(response.body).to include("Dr. Jane Smith")
    end

    it "returns 404 for a missing record" do
      get complete_response_letter_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end
end
