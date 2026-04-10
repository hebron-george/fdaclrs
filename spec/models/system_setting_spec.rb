require "rails_helper"

RSpec.describe SystemSetting, type: :model do
  describe ".get" do
    it "returns nil for a missing key" do
      expect(SystemSetting.get("nonexistent")).to be_nil
    end

    it "returns the value for an existing key" do
      SystemSetting.set("test_key", "hello")
      expect(SystemSetting.get("test_key")).to eq("hello")
    end
  end

  describe ".set" do
    it "creates a new record" do
      expect { SystemSetting.set("foo", "bar") }.to change(SystemSetting, :count).by(1)
    end

    it "updates an existing record" do
      SystemSetting.set("foo", "bar")
      SystemSetting.set("foo", "baz")
      expect(SystemSetting.count).to eq(1)
      expect(SystemSetting.get("foo")).to eq("baz")
    end
  end
end
