describe Huddle::User do
  let(:parsed_xml) { double }
  subject { described_class.new(parsed_xml) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe ".resource_path" do
    it "returns Huddle user path mask" do
      expect(described_class.resource_path).to eq("users/:id")
    end
  end

  describe ".current" do
    it "fetches API entry user and returns instance" do
      allow(described_class).to receive(:find_by_path).
        with("entry").
        and_return(:the_entry_instance)
      expect(described_class.current).to eq(:the_entry_instance)
    end
  end
end