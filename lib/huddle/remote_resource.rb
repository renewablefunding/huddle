require "open-uri"
require "oga"

module Huddle
  module RemoteResource
    BASE_URI = URI("https://api.huddle.net")

    def self.included(klass)
      klass.extend ClassMethods
    end

    attr_reader :parsed_xml

    def initialize(parsed_xml)
      @parsed_xml = parsed_xml
      @fetched_links = {}
    end

    def id
      self_link = links["self"]
      return unless self_link
      self_link.split("/").last.to_i
    end

    def fetch_from_link(link, type:)
      @fetched_links[link] ||= type.find_by_path(links[link])
    end

    def links
      @links ||= begin
        parsed_xml.xpath("link").each_with_object({}) do |link, memo|
          memo[link.get("rel")] = link.get("href")
        end
      end
    end

    module ClassMethods
      attr_accessor :resource_path

      def find(**path_options)
        find_by_path(resource_path_for(**path_options))
      end

      def find_by_path(path)
        new(fetch_xml(path))
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

      def fetch_xml(path, at_xpath: "/#{root_element}")
        response = OpenURI.open_uri(
          expand_uri(path),
          {
            "Authorization" => "OAuth2 #{Huddle.session_token}",
            "Accept" => "application/vnd.huddle.data+xml"
          }
        )
        parse_xml(response.read, at_xpath: at_xpath)
      end
    end
  end
end