require "net/http"
require "json"

module Huddle
  class Session
    class LoginError < StandardError; end

    ENDPOINT = URI("https://login.huddle.net/token")

    class << self
      def prune_keys(full_response)
        full_response.select { |key, value|
          [:access_token, :expires_in, :refresh_token].include?(key)
        }
      end

      def call_login_server(**params)
        response = Net::HTTP.post_form(ENDPOINT, **params)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        if response.code != "200"
          raise LoginError, parsed_response.fetch(:error_description, "Unknown Error")
        end
        prune_keys(parsed_response)
      end

      def generate(configuration: Huddle.configuration, authorization_code: nil)
        configuration.validate!
        authorization_code ||= configuration.default_authorization_code
        response = call_login_server(
          grant_type: "authorization_code",
          client_id: configuration.client_id,
          redirect_uri: configuration.redirect_uri,
          code: authorization_code
        )
        new(response.merge(configuration: configuration))
      end
    end

    attr_reader :refresh_token, :expires_at

    def initialize(access_token:, expires_in:, refresh_token:, configuration:)
      @access_token = access_token
      @expires_at = Time.now + expires_in
      @refresh_token = refresh_token
      @configuration = configuration
    end

    def to_s
      access_token
    end

    def access_token
      refresh! if expired?
      @access_token
    end

    def refresh!
      response = self.class.call_login_server(
        grant_type: "refresh_token",
        client_id: @configuration.client_id,
        refresh_token: refresh_token
      )
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
