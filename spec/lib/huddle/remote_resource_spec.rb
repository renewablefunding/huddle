describe Huddle::RemoteResource do
  let(:klass) { Class.new { include Huddle::RemoteResource } }

  describe "#new" do
    it "sets parsed_xml to given XML" do
      instance = klass.new(:parsed_xml)
      expect(instance.parsed_xml).to eq(:parsed_xml)
    end
  end

  describe ".fetch_xml" do
    before(:each) do
      allow(Huddle).to receive(:session_token).
        and_return("a1b2c3")
      allow(OpenURI).to receive(:open_uri).with(
        "https://api.huddle.net/the/path",
        {
          "Authorization" => "OAuth2 a1b2c3",
          "Accept" => "application/vnd.huddle.data+xml"
        }
      ).and_return(double(:read => :the_xml))
    end

    it "returns parsed xml from Huddle endpoint" do
      allow(klass).to receive(:parse_xml).
        with(:the_xml, at_xpath: "/the_root_element").
        and_return(:parsed_xml)
      allow(klass).to receive(:root_element).
        and_return(:the_root_element)
      expect(klass.fetch_xml("the/path")).
        to eq(:parsed_xml)
    end

    it "uses given root xpath element" do
      allow(klass).to receive(:parse_xml).
        with(:the_xml, at_xpath: :custom_element).
        and_return(:parsed_xml)
      expect(klass.fetch_xml("the/path", at_xpath: :custom_element)).
        to eq(:parsed_xml)
    end
  end

  describe ".parse_xml" do
    let(:parsed_xml) { double }
    before(:each) do
      allow(Oga).to receive(:parse_xml).
        with(:xml_string).
        and_return(parsed_xml)
    end

    it "parses given XML and returns root section" do
      allow(klass).to receive(:root_element).
        and_return(:the_root_element)
      allow(parsed_xml).to receive(:at_xpath).
        with("/the_root_element").
        and_return(:parsed_xml_root)
      expect(klass.parse_xml(:xml_string)).
        to eq(:parsed_xml_root)
    end

    it "uses given root xpath element" do
      allow(parsed_xml).to receive(:at_xpath).
        with(:custom_element).
        and_return(:parsed_xml_root)
      expect(klass.parse_xml(:xml_string, at_xpath: :custom_element)).
        to eq(:parsed_xml_root)
    end
  end

  describe ".root_element" do
    it "returns lowercased base class name" do
      allow(klass).to receive(:name).and_return("Foozle::Barto")
      expect(klass.root_element).to eq("barto")
    end
  end
end