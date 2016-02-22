describe Huddle::Configuration do
  shared_examples "a configuration setting" do |setting|
    it "raises an exception if not set" do
      expect { subject.send(setting) }.to raise_error(described_class::MissingSettingError)
    end

    it "returns previously set #{setting}" do
      subject.send("#{setting}=", "CollardBlaster")
      expect(subject.send(setting)).to eq("CollardBlaster")
    end
  end

  describe "#client_id" do
    include_examples "a configuration setting", :client_id
  end

  describe "#redirect_uri" do
    include_examples "a configuration setting", :redirect_uri
  end

  describe "#authorization_code" do
    include_examples "a configuration setting", :authorization_code
  end

  describe ".new" do
    it "can instantiate with settings" do
      config = described_class.new(
        client_id: "123",
        redirect_uri: "example.com",
        authorization_code: "456"
      )
      expect(config.client_id).to eq("123")
      expect(config.redirect_uri).to eq("example.com")
      expect(config.authorization_code).to eq("456")
    end
  end

  describe "#validate!" do
    it "raises error if any settings missing" do
      expect { subject.validate! }.to raise_error(
        described_class::MissingSettingError,
        "undefined settings: client_id, redirect_uri, authorization_code"
      )
    end

    it "does not raise error if all settings are set" do
      config = described_class.new(
        client_id: "123",
        redirect_uri: "example.com",
        authorization_code: "456"
      )
      expect { config.validate! }.not_to raise_error
    end
  end
end