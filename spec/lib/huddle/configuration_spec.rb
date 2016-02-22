describe Huddle::Configuration do
  shared_examples "a configuration setting" do |setting, required: true|
    if required
      it "raises an exception if not set" do
        expect { subject.send(setting) }.to raise_error(described_class::MissingSettingError)
      end
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

  describe "#default_authorization_code" do
    include_examples "a configuration setting", :default_authorization_code, required: false
  end

  describe ".new" do
    it "can instantiate with settings" do
      config = described_class.new(
        client_id: "123",
        redirect_uri: "example.com",
        default_authorization_code: "456"
      )
      expect(config.client_id).to eq("123")
      expect(config.redirect_uri).to eq("example.com")
      expect(config.default_authorization_code).to eq("456")
    end
  end

  describe "#validate!" do
    it "raises error if all required settings missing" do
      expect { subject.validate! }.to raise_error(
        described_class::MissingSettingError,
        "undefined settings: client_id, redirect_uri"
      )
    end

    it "raises error if any required settings missing" do
      subject.redirect_uri = "example.com"
      expect { subject.validate! }.to raise_error(
        described_class::MissingSettingError,
        "undefined settings: client_id"
      )
    end

    it "does not raise error if all required settings are set" do
      subject.client_id = "123"
      subject.redirect_uri = "example.com"
      expect { subject.validate! }.not_to raise_error
    end
  end
end