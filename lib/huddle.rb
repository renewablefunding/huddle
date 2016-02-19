require "huddle/version"
require "huddle/configuration"

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
