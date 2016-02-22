describe Huddle::AccessToken do
  let(:configuration) { Huddle.configuration }
  subject {
    described_class.new(access_token: "5b", expires_in: 109, refresh_token: "p8", configuration: configuration)
  }

  describe ".generate" do
    before(:each) do
      allow(Net::HTTP).to receive(:post_form).
        with(Huddle::AccessToken::ENDPOINT, {
          grant_type: "authorization_code",
          client_id: configuration.client_id,
          redirect_uri: configuration.redirect_uri,
          code: configuration.authorization_code
        }).and_return(double(:body => :a_response_body))
      allow(described_class).to receive(:from_json_response).
        with(:a_response_body, configuration: configuration).
        and_return(:the_parsed_response)
    end

    context "with specified configuration" do
      let(:configuration) {
        Huddle::Configuration.new(client_id: "33", redirect_uri: "foo.bar", authorization_code: "99")
      }

      it "generates access token from Huddle API using specified configuration" do
        expect(described_class.generate(configuration: configuration)).to eq(:the_parsed_response)
      end
    end

    context "without specified configuration" do
      it "generates access token from Huddle API using default configuration" do
        expect(described_class.generate).to eq(:the_parsed_response)
      end
    end

    it "validates configuration first" do
      expect(Net::HTTP).to receive(:post_form).never
      allow(configuration).to receive(:validate!).
        and_raise(Huddle::Configuration::MissingSettingError)
      expect {
        described_class.generate(configuration: Huddle::Configuration.new)
      }.to raise_error(Huddle::Configuration::MissingSettingError)
    end
  end

  describe ".parse_json_response" do
    it "returns hash of specific attributes from given JSON" do
      response = {
        "access_token" => "5b",
        "expires_in" => 3,
        "refresh_token" => "p8",
        "foo" => "bar"
      }.to_json

      expect(described_class.parse_json_response(response)).to eq({
        access_token: "5b",
        expires_in: 3,
        refresh_token: "p8"
      })
    end
  end

  describe ".from_json_response" do
    it "instantiates object using given JSON" do
      allow(described_class).to receive(:parse_json_response).
        with(:a_response).
        and_return({ foo: :bar })
      allow(described_class).to receive(:new).
        with({ foo: :bar, configuration: :a_config }).
        and_return(:new_instance)
      expect(
        described_class.from_json_response(:a_response, configuration: :a_config)
      ).to eq(:new_instance)
    end
  end

  describe "#access_token" do
    it "returns initialized access token if not expired yet" do
      allow(subject).to receive(:expired?).and_return(false)
      expect(subject).to receive(:refresh!).never
      expect(subject.access_token).to eq("5b")
    end

    it "refreshes before returning access token if expired" do
      allow(subject).to receive(:expired?).and_return(true)
      expect(subject).to receive(:refresh!)
      expect(subject.access_token).to eq("5b")
    end
  end

  describe "#to_s" do
    it "returns access_token" do
      allow(subject).to receive(:access_token).and_return("fancy")
      expect(subject.to_s).to eq("fancy")
    end
  end

  describe "#expires_at" do
    it "is calculated based on expires_in" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      expect(subject.expires_at).to eq(frozen_time + 109)
    end
  end

  describe "#expired?" do
    it "returns false if expires_in greater than zero" do
      allow(subject).to receive(:expires_in).and_return(5)
      expect(subject.expired?).to be false
    end

    it "returns true if expires_in less than zero" do
      allow(subject).to receive(:expires_in).and_return(-1)
      expect(subject.expired?).to be true
    end

    it "returns true if expires_in is zero" do
      allow(subject).to receive(:expires_in).and_return(0)
      expect(subject.expired?).to be true
    end
  end

  describe "#expires_in" do
    it "returns difference between now and expires_at" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      allow(subject).to receive(:expires_at).and_return(frozen_time + 84)
      expect(subject.expires_in).to eq(84)
    end
  end

  describe "#refresh!" do
    it "calls refresh endpoint and renews token" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      allow(Net::HTTP).to receive(:post_form).
        with(Huddle::AccessToken::ENDPOINT, {
          grant_type: "refresh_token",
          client_id: configuration.client_id,
          refresh_token: "p8"
        }).and_return(double(:body => :a_response_body))
      allow(described_class).to receive(:parse_json_response).
        with(:a_response_body).
        and_return({
          access_token: "fancy-new-shinies",
          expires_in: 810,
          refresh_token: "so-much-later"
        })
      subject.refresh!
      expect(subject.access_token).to eq("fancy-new-shinies")
      expect(subject.refresh_token).to eq("so-much-later")
      expect(subject.expires_at).to eq(frozen_time + 810)
    end
  end
end