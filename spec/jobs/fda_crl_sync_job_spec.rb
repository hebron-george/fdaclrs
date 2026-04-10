require "rails_helper"

RSpec.describe FdaCrlSyncJob, type: :job do
  let(:fixture) { JSON.parse(File.read(Rails.root.join("spec/fixtures/transparency/crl.json"))) }

  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/transparency/crl.json") do |_env|
        [200, { "Content-Type" => "application/json" }, fixture.to_json]
      end
    end
  end

  let(:client) { OpenFdaApi::Client.new(adapter: :test, stubs: stubs) }

  before do
    allow(OpenFdaApi::Client).to receive(:new).and_return(client)
  end

  subject(:job) { described_class.new }

  describe "#perform" do
    it "inserts records from the API response" do
      expect { job.perform }.to change(CompleteResponseLetter, :count).by(1)
    end

    it "stores the sync timestamp in SystemSetting" do
      job.perform
      expect(SystemSetting.get("last_crl_sync_at")).not_to be_nil
    end

    it "returns the application numbers of newly inserted records" do
      new_ids = job.perform
      expect(new_ids).to include("NDA012345")
    end

    it "does not duplicate records on re-run" do
      job.perform
      expect { job.perform }.not_to change(CompleteResponseLetter, :count)
    end

    it "maps all expected fields" do
      job.perform
      letter = CompleteResponseLetter.find_by(application_number: "NDA012345")
      expect(letter.company_name).to eq("Example Pharmaceuticals Inc.")
      expect(letter.approver_center).to eq("Center for Drug Evaluation and Research")
      expect(letter.letter_date).to eq(Date.new(2023, 6, 15))
    end
  end
end
