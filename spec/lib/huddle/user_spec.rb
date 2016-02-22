describe Huddle::User do
  let(:parsed_xml) { described_class.parse_xml(fixture("user.xml")) }
  subject { described_class.new(parsed_xml, session: :a_session) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe "#name" do
    it "returns display name from profile in XML" do
      expect(subject.name).to eq("Jane Doe")
    end
  end

  describe "#workspaces" do
    before(:each) do
      allow(Huddle::Workspace).to receive(:new).with(:workspace_1_xml, session: :a_session).
        and_return(:workspace_1)
      allow(Huddle::Workspace).to receive(:new).with(:workspace_2_xml, session: :a_session).
        and_return(:workspace_2)
      allow(parsed_xml).to receive(:xpath).with("membership/workspaces/workspace").
        and_return([:workspace_1_xml, :workspace_2_xml]).once
    end

    it "returns instances for each workspace element in XML" do
      expect(subject.workspaces).to eq([:workspace_1, :workspace_2])
    end

    it "is memoized" do
      subject.workspaces
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
        with("/entry", session: :a_session).
        and_return(:the_entry_instance)
      expect(described_class.current(session: :a_session)).to eq(:the_entry_instance)
    end

    it "uses default session if not specified" do
      allow(Huddle).to receive(:default_session).and_return(:the_session)
      allow(described_class).to receive(:find_by_path).
        with("/entry", session: :the_session).
        and_return(:the_entry_instance)
      expect(described_class.current).to eq(:the_entry_instance)
    end
  end
end