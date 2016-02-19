require "huddle/version"
require "huddle/configuration"
require "huddle/access_token"

module Huddle
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
