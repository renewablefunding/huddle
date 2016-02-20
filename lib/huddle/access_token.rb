require "net/http"
require "json"

module Huddle
  class AccessToken
    ENDPOINT = URI("https://login.huddle.net/token")

    class << self
      def generate
        response = Net::HTTP.post_form(
          ENDPOINT,
          grant_type: "authorization_code",
          client_id: Huddle.configuration.client_id,
          redirect_uri: Huddle.configuration.redirect_uri,
          code: Huddle.configuration.authorization_code
        )
        from_json_response(response.body)
      end

      def parse_json_response(response)
        parsed = JSON.parse(response)
        {
          access_token: parsed["access_token"],
          expires_in: parsed["expires_in"],
          refresh_token: parsed["refresh_token"]
        }
      end

      def from_json_response(response)
        new(
          parse_json_response(response)
        )
      end
    end

    attr_reader :refresh_token, :expires_at

    def initialize(access_token:, expires_in:, refresh_token:)
      @access_token = access_token
      @expires_at = Time.now + expires_in
      @refresh_token = refresh_token
    end

    def access_token
      refresh! if expired?
      @access_token
    end

    def refresh!
      response = Net::HTTP.post_form(
        ENDPOINT,
        grant_type: "refresh_token",
        client_id: Huddle.configuration.client_id,
        refresh_token: refresh_token
      )
      response = self.class.parse_json_response(response.body)
      @access_token = response[:access_token]
      @expires_at = Time.now + response[:expires_in]
      @refresh_token = response[:refresh_token]
      self
    end

    def expires_in
      expires_at - Time.now
    end

    def expired?
      expires_in <= 0
    end
  end
end
