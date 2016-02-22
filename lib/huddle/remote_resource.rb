require "open-uri"
require "oga"

module Huddle
  module RemoteResource
    BASE_URI = URI("https://api.huddle.net")

    def self.included(klass)
      klass.extend ClassMethods
    end

    attr_reader :parsed_xml, :session, :associations

    def initialize(parsed_xml, session: Huddle.default_session, fetch: false, associations: {})
      @parsed_xml = parsed_xml
      @associations = associations
      @session = session
      reload! if fetch
    end

    def to_xml
      parsed_xml.to_xml
    end

    def inspect
      "#<#{self.class}:#{"0x00%x" % (object_id << 1)} id=#{id || "nil"}>"
    end

    def id
      self_link = links["self"]
      return unless self_link
      self_link.split("/").last.to_i
    end

    def reload!
      @parsed_xml = self.class.fetch_xml(links["self"], session: session)
      @associations = {}
      self
    end

    def one(xpath, type:, fetch: false, associations: {})
      [many(xpath, type: type, fetch: fetch, associations: associations)].flatten.first
    end

    def many(xpath, type:, fetch: false, associations: {})
      @associations[xpath] ||= parsed_xml.xpath(xpath).map { |association_xml|
        type.new(association_xml, session: session, fetch: fetch, associations: associations)
      }
    end

    def fetch_from_link(association_name, link:, type:, associations: {})
      @associations[association_name] ||= begin
        type.find_by_path(links[link], session: session, associations: associations)
      end
    end

    def links
      @links ||= begin
        parsed_xml.xpath("link").each_with_object({}) do |link, memo|
          memo[link.get("rel")] = link.get("href")
        end
      end
    end

    module ClassMethods
      attr_reader :resource_path

      def find_at(masked_path)
        @resource_path = masked_path
      end

      def find(session: Huddle.default_session, **path_options)
        find_by_path(resource_path_for(**path_options), session: session)
      end

      def find_by_path(path, session: Huddle.default_session, associations: {})
        new(fetch_xml(path, session: session), session: session, associations: associations)
      end

      def resource_path_for(**path_options)
        path = resource_path.dup
        path_options.each do |key, value|
          path.gsub!(/:#{key}/, value.to_s)
        end
        path
      end

      def root_element
        self.name.split("::").last.downcase
      end

      def parse_xml(raw_xml, at_xpath: "/#{root_element}")
        Oga.parse_xml(raw_xml).at_xpath(at_xpath)
      end

      def expand_uri(uri_or_path)
        URI(uri_or_path).tap { |uri|
          uri.path.prepend("/") unless uri.path[0] == "/"
          uri.scheme ||= BASE_URI.scheme
          uri.host ||= BASE_URI.host
        }.to_s
      end

      def fetch_xml(path, at_xpath: "/#{root_element}", session:)
        response = OpenURI.open_uri(
          expand_uri(path),
          {
            "Authorization" => "OAuth2 #{session}",
            "Accept" => "application/vnd.huddle.data+xml"
          }
        )
        parse_xml(response.read, at_xpath: at_xpath)
      end
    end
  end
end