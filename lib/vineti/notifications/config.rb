module Vineti
  module Notifications
    class Config
      cattr_accessor :vineti_config
      def self.instance
        self.vineti_config ||= begin
          config = Vineti::Config.new(Vineti::Config::Sources::EnvSource)
          config.logger = Rails.logger
          config.define_keys(YAML.load_file(Rails.root.join('config', 'configuration_keys.yml')))
          config
        end
      end
    end
  end
end
