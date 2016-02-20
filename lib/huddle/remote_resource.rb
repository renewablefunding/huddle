require "open-uri"
require "oga"

module Huddle
  module RemoteResource
    def self.included(klass)
      klass.extend ClassMethods
    end

    attr_reader :parsed_xml

    def initialize(parsed_xml)
      @parsed_xml = parsed_xml
    end

    module ClassMethods
      def root_element
        self.name.split("::").last.downcase
      end

      def parse_xml(raw_xml, at_xpath: "/#{root_element}")
        Oga.parse_xml(raw_xml).at_xpath(at_xpath)
      end

      def fetch_xml(path, at_xpath: "/#{root_element}")
        response = OpenURI.open_uri(
          "https://api.huddle.net/#{path}",
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