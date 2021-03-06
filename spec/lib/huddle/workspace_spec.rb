describe Huddle::Workspace do
  let(:parsed_xml) { described_class.parse_xml(fixture("workspace.xml")) }
  subject { described_class.new(parsed_xml, session: :a_session) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end

  describe "#type" do
    it "returns type attribute from XML root" do
      expect(subject.type).to eq("shared")
    end
  end

  describe "#title" do
    it "returns type attribute from XML root" do
      expect(subject.title).to eq("Workspace One")
    end
  end

  describe "#document_library_folder" do
    it "returns root document library folder from links" do
      allow(subject).to receive(:fetch_from_link).
        with("folder", link: "documentLibrary", type: Huddle::Folder, associations: { "workspace" => subject }).
        and_return(:the_folder)
      expect(subject.document_library_folder).to eq(:the_folder)
    end
  end

  describe ".resource_path" do
    it "returns Huddle workspace path mask" do
      expect(described_class.resource_path).to eq("/workspaces/:id")
    end
  end
end