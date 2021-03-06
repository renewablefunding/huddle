describe Huddle::Session do
  let(:configuration) { Huddle.configuration }
  let(:authorization_code) { configuration.default_authorization_code }
  subject {
    described_class.new(access_token: "5b", expires_in: 109, refresh_token: "p8", configuration: configuration)
  }

  describe ".prune_keys" do
    it "ignores any keys not used for session initialization" do
      desired_keys = {
        access_token: "5b",
        expires_in: 109,
        refresh_token: "p8"
      }
      expect(described_class.prune_keys(desired_keys.merge(foo: "bar"))).
        to eq(desired_keys)
    end
  end

  describe ".call_login_server" do
    before(:each) do
      allow(described_class).to receive(:prune_keys).
        with(body).
        and_return(body)
      allow(Net::HTTP).to receive(:post_form).
        with(Huddle::Session::ENDPOINT, {
          foo: "bar",
          baz: "buzz"
        }).and_return(double(body: body.to_json, code: code))
    end

    context "when response is 200" do
      let(:body) { { :access_token => "a_token" } }
      let(:code) { "200" }

      it "calls login endpoint with given params and returns parsed response" do
        expect(described_class.call_login_server(foo: "bar", baz: "buzz")).
          to eq(access_token: "a_token")
      end
    end

    context "when response is not 200 and error description is returned" do
      let(:body) { { :error_description => "That didn't work" } }
      let(:code) { "403" }

      it "raises a LoginError with the error description from the server" do
        expect {
          described_class.call_login_server(foo: "bar", baz: "buzz")
        }.to raise_error(described_class::LoginError, "That didn't work")
      end
    end

    context "when response is not 200 and error description is returned" do
      let(:body) { { :invalid => "response" } }
      let(:code) { "403" }

      it "raises a LoginError with the error description from the server" do
        expect {
          described_class.call_login_server(foo: "bar", baz: "buzz")
        }.to raise_error(described_class::LoginError, "Unknown Error")
      end
    end
  end

  describe ".generate" do
    before(:each) do
      allow(described_class).to receive(:call_login_server).
        with({
          grant_type: "authorization_code",
          client_id: configuration.client_id,
          redirect_uri: configuration.redirect_uri,
          code: authorization_code
        }).and_return(foo: "bar")
      allow(described_class).to receive(:new).
        with(foo: "bar", configuration: configuration).
        and_return(:the_session)
    end

    context "with specified configuration" do
      let(:configuration) {
        Huddle::Configuration.new(client_id: "33", redirect_uri: "foo.bar", default_authorization_code: "99")
      }

      it "generates access token from Huddle API using specified configuration" do
        expect(described_class.generate(configuration: configuration)).to eq(:the_session)
      end
    end

    context "without specified configuration" do
      it "generates access token from Huddle API using default configuration" do
        expect(described_class.generate).to eq(:the_session)
      end
    end

    context "with specified authorization code" do
      let(:authorization_code) { "overridden_code" }

      it "uses specified code in place of default code" do
        expect(described_class.generate(authorization_code: authorization_code)).
          to eq(:the_session)
      end
    end

    it "validates configuration first" do
      expect(described_class).to receive(:call_login_server).never
      allow(configuration).to receive(:validate!).
        and_raise(Huddle::Configuration::MissingSettingError)
      expect {
        described_class.generate(configuration: Huddle::Configuration.new)
      }.to raise_error(Huddle::Configuration::MissingSettingError)
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
      allow(described_class).to receive(:call_login_server).
        with({
          grant_type: "refresh_token",
          client_id: configuration.client_id,
          refresh_token: "p8"
        }).and_return({
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