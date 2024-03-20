require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/config/environment.rb', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'aws-sdk-sns'
require 'aws-sdk-ses'
require 'jsonapi/rails'
require 'factory_bot_rails'
require 'faker'
require 'stomp_droid'
require 'database_cleaner/active_record'
require 'devise'
require 'oauth2'
require 'vineti/config/rspec'

require './spec/support/activemq_spec_helper'

Vineti::Config::RSpec.configuration.config_instance = Vineti::Notifications::Config.instance
Rails.application.load_tasks

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # For Devise > 4.1.1
  config.include Devise::Test::ControllerHelpers, type: :controller
  # config.include Devise::Test::ControllerHelpers, type: :view
  # config.include SignInHelpers, type: :controller
  # config.include SignInHelpers, type: :acceptance

  # https://github.com/wardencommunity/warden/wiki/testing
  # Warden is what Devise is based on. It is a general Rack authentication framework created by Daniel Neighman
  # These helpers contribute to create login method
  config.include Warden::Test::Helpers
  config.include ActiveMQHelper
end

def api_sign_in(user, request)
  user.create_new_auth_token.except('expiry').each do |k, v|
    request.headers[k] = v
  end
end

def expire_token(user, token)
  client_id = token['client']
  if user.tokens[client_id]
    user.tokens[client_id]['expiry'] = (Time.current - (DeviseTokenAuth.token_lifespan.to_f + 10.seconds)).to_i
    user.save!
  end
end
