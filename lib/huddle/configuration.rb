module Huddle
  class Configuration
    class MissingSettingError < StandardError; end

    class << self
      def settings(*names, required: true)
        names.each do |name|
          setting name, required: required
        end
      end

      def setting(name, required: true)
        required_settings << name if required
        attr_writer name
        define_method(name) do
          value = instance_variable_get(:"@#{name}")
          if required && !value
            raise MissingSettingError, "#{name} must be defined"
          end
          value
        end
      end

      def required_settings
        @required_settings ||= []
      end
    end

    settings :client_id, :redirect_uri
    setting :default_authorization_code, required: false

    def initialize(**settings)
      settings.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    def validate!
      missing = self.class.required_settings.select { |setting|
        instance_variable_get(:"@#{setting}").nil?
      }
      unless missing.empty?
        raise MissingSettingError, "undefined settings: #{missing.join(", ")}"
      end
    end
  end
end