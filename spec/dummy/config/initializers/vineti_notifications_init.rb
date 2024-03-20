# Note: This initialization was earlier part of vineti-notifications engine.

# The engine had dependencies on platform, specifically for CFG fetch.
# The default source for config in notification-engine was environment.

# Earlier this initializer was run when the notifications engine was loaded
# as part of bundle load. And if there was messages in the queue when the pod
# starts, the subscribers starts picking it up, but those threads did not
# have access to correct configs. AWS, WSO2 creds and other configs were not
# right (or present in ENV source) and so email sending failed.
# So we moved this to initializers of the platform

# Ref: https://vineti.atlassian.net/browse/PLATFORM-4591

enable_activemq = Vineti::Notifications::Config.instance.feature('vineti_activemq_enable')

if defined?(Rails::Server) && enable_activemq
  Vineti::Notifications::ConsumerSeeder.run
end
