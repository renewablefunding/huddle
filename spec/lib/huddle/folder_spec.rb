describe Huddle::Folder do
  let(:parsed_xml) { described_class.parse_xml(fixture("folder.xml")) }
  subject { described_class.new(parsed_xml) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end
end