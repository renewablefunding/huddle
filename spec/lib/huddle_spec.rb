describe Huddle do
  it 'has a version number' do
    expect(Huddle::VERSION).not_to be nil
  end

  describe "#configuration" do
    it "returns a configuration object" do
      expect(described_class.configuration).to be_a(Huddle::Configuration)
    end

    it "returns the same configuration object multiple times" do
      config = described_class.configuration
      expect(described_class.configuration).to eq(config)
    end
  end

  describe "#configure" do
    it "yields configuration object to given block" do
      expect(described_class.configuration).to receive(:do_a_thing!)
      described_class.configure do |c|
        c.do_a_thing!
      end
    end
  end

  describe "#authenticate!" do
    it "generates and stores an access token" do
      allow(Huddle::Session).to receive(:generate).
        and_return(:an_access_token)
      described_class.authenticate!
      expect(described_class.default_session).to eq(:an_access_token)
    end
  end
end
