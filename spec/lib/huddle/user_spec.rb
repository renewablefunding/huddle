describe Huddle::User do
  let(:parsed_xml) { double }
  subject { described_class.new(parsed_xml) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe ".current" do
    it "fetches API entry user and returns instance" do
      allow(described_class).to receive(:fetch_xml).
        with("entry").
        and_return(parsed_xml)
      allow(described_class).to receive(:new).
        with(parsed_xml).
        and_return(:the_entry_instance)
      expect(described_class.current).to eq(:the_entry_instance)
    end
  end
end