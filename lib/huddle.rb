require "huddle/version"
require "huddle/configuration"
require "huddle/remote_resource"
require "huddle/session"
require "huddle/user"
require "huddle/workspace"
require "huddle/folder"

module Huddle
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def default_session
      @default_session ||= Huddle::Session.generate
    end
  end
end
