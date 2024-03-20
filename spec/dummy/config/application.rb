require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "vineti/notifications"
require 'devise'
require 'devise_token_auth'
require 'dotenv/load'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    Dotenv.load Rails.root.join('.env')
  end
end
