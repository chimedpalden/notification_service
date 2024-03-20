module Vineti
  module Notifications
    class Engine < ::Rails::Engine
      isolate_namespace Vineti::Notifications
      config.generators do |g|
        g.test_framework :rspec
        g.assets false
        g.helper false
      end

      initializer "vineti_notifications.factories", after: "factory_bot.set_factory_paths" do
        FactoryBot.definition_file_paths << File.expand_path('../../../../spec/factories', __FILE__) if defined?(FactoryBot)
      end

      config.eager_load_paths += %W(#{config.root}/lib/ #{config.root}/app/concepts)
      config.autoload_paths += %W(#{config.root}/lib/ #{config.root}/app/concepts)
    end
  end
end
