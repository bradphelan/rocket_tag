module RocketTag
  class Configuration
    VALID_CONFIG_KEYS = [
      :force_lowercase
    ]

    DEFAULT_FORCE_LOWERCASE = false

    attr_accessor *VALID_CONFIG_KEYS

    def initialize
      self.reset
    end

    def options
      VALID_CONFIG_KEYS.each_with_object({}) do |config_key, hash|
        hash[config_key] = self.send(config_key)
      end
    end

    def reset
      VALID_CONFIG_KEYS.each do |key|
        self.send "#{key}=", self.class.const_get("DEFAULT_#{key.upcase}")
      end
    end
  end
end
