describe Huddle::RemoteResource do
  let(:klass) { Class.new { include Huddle::RemoteResource } }
  let(:session) { double(Huddle::Session, to_s: "a_token") }
  let(:parsed_xml) { klass.parse_xml(fixture("resource_with_links.xml"), at_xpath: "/resource") }
  subject { klass.new(parsed_xml, session: session) }

  describe "#new" do
    it "sets parsed_xml to given XML" do
      expect(subject.parsed_xml).to eq(parsed_xml)
    end

    it "uses default session if none given" do
      session = double
      allow(Huddle).to receive(:default_session).and_return(:a_session)
      using_default = klass.new(parsed_xml)
      expect(using_default.instance_variable_get(:@session)).to eq(:a_session)
    end
  end

  describe "#inspect" do
    it "returns simplified inspect without parsed_xml" do
      allow(klass).to receive(:to_s).and_return("MyClass")
      expect(subject.inspect).to eq(
        "#<MyClass:#{"0x00%x" % (subject.object_id << 1)} id=123>"
      )
    end
  end

  describe "#fetch_from_link" do
    let(:type_class) { double }
    before(:each) do
      allow(type_class).to receive(:find_by_path).
        with("http://example.com/foo/1", session: session).
        and_return(:the_fetched_link).once
    end

    it "finds given link by path and instantiates given type" do
      expect(subject.fetch_from_link("foo", type: type_class)).
        to eq(:the_fetched_link)
    end

    it "fetches links only once" do
      subject.fetch_from_link("foo", type: type_class)
      expect(subject.fetch_from_link("foo", type: type_class)).
        to eq(:the_fetched_link)
    end
  end

  describe "#links" do
    it "returns hash of links from XML" do
      expect(subject.links).to eq({
        "bar" => "http://example.com/bar/2",
        "foo" => "http://example.com/foo/1",
        "self" => "http://example.com/resource/123"
      })
    end
  end

  describe "#id" do
    it "returns last path element from self link, as integer" do
      expect(subject.id).to eq(123)
    end

    it "returns nil if no self link" do
      allow(subject).to receive(:links).
        and_return({})
      expect(subject.id).to be_nil
    end
  end

  describe ".find" do
    before(:each) do
      allow(klass).to receive(:resource_path_for).
        with(option: 1, other_option: 2).
        and_return(:the_path)
    end

    it "returns instance created from XML at interpolated resource path" do
      allow(klass).to receive(:find_by_path).
        with(:the_path, session: session).
        and_return(:new_instance)
      expect(klass.find(option: 1, other_option: 2, session: session)).
        to eq(:new_instance)
    end

    it "uses default session if not specified" do
      allow(Huddle).to receive(:default_session).and_return(:a_session)
      allow(klass).to receive(:find_by_path).
        with(:the_path, session: :a_session).
        and_return(:new_instance)
      expect(klass.find(option: 1, other_option: 2)).
        to eq(:new_instance)
    end
  end

  describe ".find_by_path" do
    it "returns instance created from fetched XML at given path" do
      allow(klass).to receive(:fetch_xml).
        with(:the_path, session: session).
        and_return(:fetched_xml)
      allow(klass).to receive(:new).
        with(:fetched_xml, session: session).
        and_return(:new_instance)
      expect(klass.find_by_path(:the_path, session: session)).to eq(:new_instance)
    end

    it "uses default session if not specified" do
      allow(Huddle).to receive(:default_session).and_return(:a_session)
      allow(klass).to receive(:fetch_xml).
        with(:the_path, session: :a_session).
        and_return(:fetched_xml)
      allow(klass).to receive(:new).
        with(:fetched_xml, session: :a_session).
        and_return(:new_instance)
      expect(klass.find_by_path(:the_path)).to eq(:new_instance)
    end
  end

  describe ".find_at" do
    it "sets resource_path" do
      klass.find_at "fabaloo"
      expect(klass.resource_path).to eq("fabaloo")
    end
  end

  describe ".resource_path_for" do
    it "returns interpolated resource_path with given options" do
      allow(klass).to receive(:resource_path).
        and_return("resource/:something/:id")
      expect(klass.resource_path_for(something: "foo", id: "bar")).
        to eq("resource/foo/bar")
    end
  end

  describe ".expand_uri" do
    it "returns argument if scheme already set" do
      expect(klass.expand_uri("http://example.com/goof")).
        to eq("http://example.com/goof")
    end

    it "adds scheme and host if not provided" do
      expect(klass.expand_uri("/goof")).
        to eq("https://api.huddle.net/goof")
    end

    it "works with non-root paths" do
      expect(klass.expand_uri("goof")).
        to eq("https://api.huddle.net/goof")
    end
  end

  describe ".fetch_xml" do
    before(:each) do
      allow(klass).to receive(:expand_uri).with("/the/path").
        and_return("fully_qualified_uri")
      allow(OpenURI).to receive(:open_uri).with(
        "fully_qualified_uri",
        {
          "Authorization" => "OAuth2 a_token",
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
      expect(klass.fetch_xml("/the/path", session: session)).
        to eq(:parsed_xml)
    end

    it "uses given root xpath element" do
      allow(klass).to receive(:parse_xml).
        with(:the_xml, at_xpath: :custom_element).
        and_return(:parsed_xml)
      expect(klass.fetch_xml("/the/path", at_xpath: :custom_element, session: session)).
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