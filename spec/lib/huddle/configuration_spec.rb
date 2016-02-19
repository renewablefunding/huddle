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
end