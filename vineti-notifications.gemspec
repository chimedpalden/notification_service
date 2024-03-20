$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "vineti/notifications/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "vineti-notifications"
  spec.version     = Vineti::Notifications::VERSION
  spec.authors     = %w[sudeep-vineti sachin-vineti]
  spec.email       = %w[sudeep.tarlekar@vineti.com sachin.mittal@vineti.com]
  spec.homepage    = ""
  spec.summary     = "Summary of Vineti::Notifications."
  spec.description = "Description of Vineti::Notifications."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  spec.add_dependency 'aws-sdk-ses', '~> 1.14.0'
  spec.add_dependency 'aws-sdk-sns', '~> 1.9.0'
  spec.add_dependency 'aws-ses', '~> 0.6.0'
  spec.add_dependency 'devise', '>= 4.7'
  spec.add_dependency 'devise_token_auth', '>= 1.1'
  spec.add_dependency 'dotenv-rails', '2.7.5'
  spec.add_dependency 'jsonapi-rails', '~> 0.4.0'
  spec.add_dependency 'jsonapi_errors_handler', '0.1.9'
  spec.add_dependency 'oauth2', '~> 1.4'
  spec.add_dependency 'paper_trail', '>= 10.2.0'
  spec.add_dependency 'pg', '~> 1.1.3'
  spec.add_dependency "rails", '>= 5.0', '>= 6.0'
  spec.add_dependency 'stomp', '1.4.9'
  spec.add_dependency 'vineti-templates', '>= 0.2.0'
  spec.add_development_dependency 'factory_bot_rails', '~> 4.11.1'
  spec.add_development_dependency 'faker', '1.9.6'
  spec.add_development_dependency 'rspec-rails', '~> 3.8.2'
  spec.add_development_dependency 'simplecov', '0.16.1'
  spec.add_development_dependency 'stomp_droid'

  spec.test_files = Dir["spec/**/*"]
end
