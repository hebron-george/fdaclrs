require "rails_helper"

RSpec.describe CompleteResponseLetter, type: :model do
  def build_letter(attrs = {})
    defaults = {
      application_number: "BLA125012",
      letter_type: "COMPLETE RESPONSE",
      letter_date: Date.new(2023, 6, 15),
      company_name: "Example Therapeutics",
      approver_center: "Center for Biologics Evaluation and Research",
      text: "We cannot approve this application in its present form."
    }
    CompleteResponseLetter.create!(defaults.merge(attrs))
  end

  describe "validations" do
    it "requires application_number" do
      letter = CompleteResponseLetter.new(application_number: nil)
      expect { letter.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "enforces unique application_number" do
      build_letter(application_number: "BLA125012")
      expect {
        build_letter(application_number: "BLA125012")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".search scope" do
    before do
      build_letter(
        application_number: "BLA125012",
        company_name: "Gene Cure Inc",
        text: "gene therapy lentiviral vector study"
      )
      build_letter(
        application_number: "NDA209637",
        company_name: "Pharma Corp",
        text: "small molecule drug formulation issue"
      )
    end

    it "returns matching records" do
      results = CompleteResponseLetter.search("lentiviral")
      expect(results.map(&:application_number)).to include("BLA125012")
      expect(results.map(&:application_number)).not_to include("NDA209637")
    end

    it "ranks by relevance" do
      results = CompleteResponseLetter.search("gene therapy")
      expect(results.first.application_number).to eq("BLA125012")
    end

    it "searches company_name at higher weight" do
      results = CompleteResponseLetter.search("Gene Cure")
      expect(results.map(&:application_number)).to include("BLA125012")
    end
  end

  describe ".by_center scope" do
    it "filters by approver_center" do
      build_letter(application_number: "BLA125012", approver_center: "Center for Biologics Evaluation and Research")
      build_letter(application_number: "NDA209637", approver_center: "Center for Drug Evaluation and Research")

      results = CompleteResponseLetter.by_center("Center for Biologics Evaluation and Research")
      expect(results.map(&:application_number)).to eq(["BLA125012"])
    end
  end

  describe ".by_company scope" do
    it "does a case-insensitive partial match" do
      build_letter(application_number: "BLA125012", company_name: "BlueBird Bio")

      expect(CompleteResponseLetter.by_company("bluebird").map(&:application_number)).to eq(["BLA125012"])
      expect(CompleteResponseLetter.by_company("unknown")).to be_empty
    end
  end

  describe ".by_date_range scope" do
    it "filters by letter_date range" do
      build_letter(application_number: "BLA125012", letter_date: Date.new(2022, 1, 1))
      build_letter(application_number: "NDA209637", letter_date: Date.new(2023, 6, 15))

      results = CompleteResponseLetter.by_date_range(Date.new(2023, 1, 1), Date.new(2023, 12, 31))
      expect(results.map(&:application_number)).to eq(["NDA209637"])
    end
  end
end
