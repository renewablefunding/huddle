describe Huddle::User do
  let(:parsed_xml) { double }
  subject { described_class.new(parsed_xml) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe "#workspaces" do
    it "returns instances for each workspace element in XML" do
      allow(Huddle::Workspace).to receive(:new).with(:workspace_1_xml).
        and_return(:workspace_1)
      allow(Huddle::Workspace).to receive(:new).with(:workspace_2_xml).
        and_return(:workspace_2)
      allow(parsed_xml).to receive(:xpath).with("membership/workspaces/workspace").
        and_return([:workspace_1_xml, :workspace_2_xml])
      expect(subject.workspaces).to eq([:workspace_1, :workspace_2])
    end
  end

  describe ".resource_path" do
    it "returns Huddle user path mask" do
      expect(described_class.resource_path).to eq("/users/:id")
    end
  end

  describe ".current" do
    it "fetches API entry user and returns instance" do
      allow(described_class).to receive(:find_by_path).
        with("/entry").
        and_return(:the_entry_instance)
      expect(described_class.current).to eq(:the_entry_instance)
    end
  end
end