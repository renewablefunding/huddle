describe Huddle::Folder do
  let(:parsed_xml) { described_class.parse_xml(fixture("folder.xml")) }
  subject { described_class.new(parsed_xml, session: :a_session) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe "#name" do
    it "returns display name from root attribute in XML" do
      expect(subject.name).to eq("Folder One")
    end
  end

  describe "#owner" do
    it "returns user instance for owner" do
      allow(subject).to receive(:one).
        with("actor[@rel='owner']", type: Huddle::User).
        and_return(:the_owner)
      expect(subject.owner).to eq(:the_owner)
    end
  end

  describe "#folders" do
    it "returns instances for each folder element" do
      allow(subject).to receive(:workspace).
        and_return(:the_workspace)
      allow(subject).to receive(:many).
        with(
          "folders/folder",
          type: Huddle::Folder,
          associations: { "workspace" => :the_workspace }
        ).
        and_return([:folder_1, :folder_2])
      expect(subject.folders).to eq([:folder_1, :folder_2])
    end
  end

  describe "#workspace" do
    it "returns workspace instance" do
      allow(subject).to receive(:one).
        with("workspace", type: Huddle::Workspace, fetch: true).
        and_return(:workspace)
      expect(subject.workspace).to eq(:workspace)
    end
  end
end