describe Huddle::AccessToken do
  subject {
    described_class.new(access_token: "5b", expires_in: 109, refresh_token: "p8")
  }

  describe ".generate" do
    it "gets access token from Huddle API and instantiates" do
      allow(Net::HTTP).to receive(:post_form).
        with(Huddle::AccessToken::ENDPOINT, {
          grant_type: "authorization_code",
          client_id: "1234",
          redirect_uri: "zoo.net",
          code: "5678"
        }).and_return(double(:body => :a_response_body))
      allow(described_class).to receive(:from_json_response).
        with(:a_response_body).
        and_return(:the_parsed_response)
      expect(described_class.generate).to eq(:the_parsed_response)
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
        and_return(:parsed_response)
      allow(described_class).to receive(:new).
        with(:parsed_response).
        and_return(:new_instance)
      expect(described_class.from_json_response(:a_response)).to eq(:new_instance)
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
          client_id: "1234",
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