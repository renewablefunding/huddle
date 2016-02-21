require "huddle/version"
require "huddle/configuration"
require "huddle/remote_resource"
require "huddle/access_token"
require "huddle/user"
require "huddle/workspace"
require "huddle/folder"

module Huddle
  class << self
    attr_reader :session_token

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def authenticate!
      @session_token = Huddle::AccessToken.generate
    end
  end
end
