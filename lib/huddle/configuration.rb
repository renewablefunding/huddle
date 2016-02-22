module Huddle
  class Configuration
    class MissingSettingError < StandardError; end

    def self.setting(*names)
      names.each do |name|
        attr_writer name
        define_method(name) do
          instance_variable_get(:"@#{name}") ||
            (raise MissingSettingError, "#{name} must be defined")
        end
      end
    end

    setting :client_id, :redirect_uri, :authorization_code

    def initialize(**settings)
      settings.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    def validate!
      missing = [:client_id, :redirect_uri, :authorization_code].select { |setting|
        instance_variable_get(:"@#{setting}").nil?
      }
      unless missing.empty?
        raise MissingSettingError, "undefined settings: #{missing.join(", ")}"
      end
    end
  end
end