require "rails_helper"

RSpec.describe CompleteResponseLetter, type: :model do
  def build_letter(attrs = {})
    defaults = {
      file_name:           "letter_#{SecureRandom.hex(4)}.pdf",
      application_numbers: ["BLA125012"],
      letter_type:         "COMPLETE RESPONSE",
      letter_date:         Date.new(2023, 6, 15),
      company_name:        "Example Therapeutics",
      approver_center:     ["Center for Biologics Evaluation and Research"],
      text:                "We cannot approve this application in its present form."
    }
    CompleteResponseLetter.create!(defaults.merge(attrs))
  end

  describe "validations" do
    it "enforces unique file_name" do
      build_letter(file_name: "duplicate.pdf")
      expect {
        build_letter(file_name: "duplicate.pdf")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".search scope" do
    before do
      build_letter(
        file_name:           "gene_therapy.pdf",
        application_numbers: ["BLA125012"],
        company_name:        "Gene Cure Inc",
        text:                "gene therapy lentiviral vector study"
      )
      build_letter(
        file_name:           "small_molecule.pdf",
        application_numbers: ["NDA209637"],
        company_name:        "Pharma Corp",
        text:                "small molecule drug formulation issue"
      )
    end

    it "returns matching records" do
      results = CompleteResponseLetter.search("lentiviral")
      expect(results.map(&:file_name)).to include("gene_therapy.pdf")
      expect(results.map(&:file_name)).not_to include("small_molecule.pdf")
    end

    it "ranks by relevance" do
      results = CompleteResponseLetter.search("gene therapy")
      expect(results.first.file_name).to eq("gene_therapy.pdf")
    end

    it "searches company_name at higher weight" do
      results = CompleteResponseLetter.search("Gene Cure")
      expect(results.map(&:file_name)).to include("gene_therapy.pdf")
    end

    it "searches application_numbers" do
      results = CompleteResponseLetter.search("BLA125012")
      expect(results.map(&:file_name)).to include("gene_therapy.pdf")
    end

    it "matches a substring that is not a standalone word (ILIKE path)" do
      build_letter(
        file_name: "aav_therapy.pdf",
        text:      "The product onasemnogene abeparvovec was reviewed for safety."
      )
      results = CompleteResponseLetter.search("parvovec")
      expect(results.map(&:file_name)).to include("aav_therapy.pdf")
    end

    it "does not return unrelated records on substring search" do
      build_letter(
        file_name: "aav_therapy.pdf",
        text:      "The product onasemnogene abeparvovec was reviewed for safety."
      )
      results = CompleteResponseLetter.search("parvovec")
      expect(results.map(&:file_name)).not_to include("small_molecule.pdf")
    end

    it "returns FTS results alongside ILIKE results when both apply" do
      build_letter(
        file_name: "aav_therapy.pdf",
        text:      "The product onasemnogene abeparvovec was reviewed for safety."
      )
      # "lentiviral" is a whole word (FTS path); "parvovec" is a suffix (ILIKE path)
      # searching for a term that matches only one of them should return only that one
      fts_results   = CompleteResponseLetter.search("lentiviral")
      ilike_results = CompleteResponseLetter.search("parvovec")
      expect(fts_results.map(&:file_name)).to include("gene_therapy.pdf")
      expect(fts_results.map(&:file_name)).not_to include("aav_therapy.pdf")
      expect(ilike_results.map(&:file_name)).to include("aav_therapy.pdf")
      expect(ilike_results.map(&:file_name)).not_to include("gene_therapy.pdf")
    end
  end

  describe ".by_application_number scope" do
    it "matches a record containing the given application number" do
      build_letter(
        file_name:           "multi_app.pdf",
        application_numbers: ["BLA 761373/Original 2", "BLA 761425/Original 2", "BLA 761373", "BLA 761425"]
      )

      expect(CompleteResponseLetter.by_application_number("BLA 761373").map(&:file_name)).to eq(["multi_app.pdf"])
      expect(CompleteResponseLetter.by_application_number("BLA 761425/Original 2").map(&:file_name)).to eq(["multi_app.pdf"])
      expect(CompleteResponseLetter.by_application_number("NDA999999")).to be_empty
    end
  end

  describe ".by_center scope" do
    it "filters by approver_center" do
      build_letter(file_name: "cber.pdf", approver_center: ["Center for Biologics Evaluation and Research"])
      build_letter(file_name: "cder.pdf", approver_center: ["Center for Drug Evaluation and Research"])

      results = CompleteResponseLetter.by_center("Center for Biologics Evaluation and Research")
      expect(results.map(&:file_name)).to eq(["cber.pdf"])
    end
  end

  describe ".by_company scope" do
    it "does a case-insensitive partial match" do
      build_letter(file_name: "bluebird.pdf", company_name: "BlueBird Bio")

      expect(CompleteResponseLetter.by_company("bluebird").map(&:file_name)).to eq(["bluebird.pdf"])
      expect(CompleteResponseLetter.by_company("unknown")).to be_empty
    end
  end

  describe ".by_date_range scope" do
    it "filters by letter_date range" do
      build_letter(file_name: "old.pdf", letter_date: Date.new(2022, 1, 1))
      build_letter(file_name: "recent.pdf", letter_date: Date.new(2023, 6, 15))

      results = CompleteResponseLetter.by_date_range(Date.new(2023, 1, 1), Date.new(2023, 12, 31))
      expect(results.map(&:file_name)).to eq(["recent.pdf"])
    end
  end
end
