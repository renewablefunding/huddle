describe Huddle::Workspace do
  let(:parsed_xml) { described_class.parse_xml(fixture("workspace.xml")) }
  subject { described_class.new(parsed_xml) }

  it "is a RemoteResource" do
    expect(subject).to be_a(Huddle::RemoteResource)
  end
end