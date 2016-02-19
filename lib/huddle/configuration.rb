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
  end
end