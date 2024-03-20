# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

# Declare your gem's dependencies in vineti-notifications.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

gem 'activerecord-postgres_enum', '~> 0.6.0'
gem 'airbrake', '10.0.1'
gem 'event_service_client', git: 'git@github.com:vinetiworks/event-service-client.git', tag: 'v1.1.6'
gem 'jsonapi-rails', '~> 0.4.0'
gem 'jsonapi_errors_handler', '0.1.9'
gem 'oauth2', '1.4.4'
gem 'paper_trail', '10.2.0'
gem 'pundit', '2.0.0'
gem 'rest-client', '~> 2.1.0'
gem 'rswag'
gem 'stomp', '1.4.9'
gem 'trailblazer-rails', '2.1.7'
gem 'vineti-client', git: 'git@github.com:vinetiworks/vineti-client.git', tag: 'v0.2.2'
gem 'vineti-config', git: 'git@github.com:vinetiworks/vineti-config.git', tag: 'v3.0.4'
gem 'vineti-templates', git: 'git@github.com:vinetiworks/vineti-templates.git', tag: 'v1.0.6'

group :development, :test do
  gem 'brakeman', '4.7.1'
  gem 'bundler-audit'
  gem 'byebug'
  gem 'pry-byebug'
  gem 'rubocop', '0.76.0'
  gem 'rubocop-performance', '1.5.0'
  gem 'rubocop-rails', '2.3.2'
  gem 'rubocop-rspec', '1.36.0'
  gem "ruby_audit"
  gem 'vcr', '4.0.0'
  gem 'webmock'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'simplecov'
end
