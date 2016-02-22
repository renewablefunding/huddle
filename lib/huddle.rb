require "huddle/version"
require "huddle/configuration"
require "huddle/remote_resource"
require "huddle/session"
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
      @session_token = Huddle::Session.generate
    end
  end
end
