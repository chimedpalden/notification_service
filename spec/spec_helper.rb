Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'webmock/rspec'
require 'vcr'
require 'spec_data/dummy_error'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch

    load_profile "test_frameworks"

    track_files "**/*.rake"
    track_files "**/*.rb"

    add_filter '/spec/'
    add_filter '/bin/'
    add_filter %r{^/config/}
    add_filter %r{^/db/}
    if ENV['TEST_ENV_NUMBER']
      command_name "Rspec#{ENV['TEST_ENV_NUMBER']}"
    end
  end
end

VCR.configure do |c|
  c.ignore_hosts 'config.vineti.com'
  c.cassette_library_dir = 'spec/test_data/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"
end
