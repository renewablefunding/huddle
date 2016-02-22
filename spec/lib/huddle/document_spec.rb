describe Huddle::Document do
  let(:parsed_xml) { described_class.parse_xml(fixture("document.xml")) }
  subject { described_class.new(parsed_xml, session: :a_session) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe "#title" do
    it "returns title attribute from XML" do
      expect(subject.title).to eq("Document One")
    end
  end

  describe "#description" do
    it "returns description attribute from XML" do
      expect(subject.description).to eq("The first document")
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

  describe "#folder" do
    it "returns parent-folder from links" do
      allow(subject).to receive(:workspace).
        and_return(:the_workspace)
      allow(subject).to receive(:fetch_from_link).
        with("folder", link: "parent-folder", type: Huddle::Folder, associations: { "workspace" => :the_workspace }).
        and_return(:the_folder)
      expect(subject.folder).to eq(:the_folder)
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