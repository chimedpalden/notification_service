require 'paper_trail/version'

require 'vineti/notifications/config'
require 'vineti/notifications/application_record'
require 'vineti/notifications/event'
require 'vineti/notifications/subscriber'
require 'vineti/notifications/event_subscriber'
require 'vineti/notifications/subscriber/email_subscriber'
require 'vineti/notifications/subscriber/webhook_subscriber'
require 'vineti/notifications/subscriber/internal_api_subscriber'
require 'vineti/notifications/webhook_subscription'
require 'vineti/notifications/email_subscription'
require 'vineti/notifications/internal_api_subscription'

# Note: This initialization was moved out here to one of the initializers
# of the platform. (platform/config/initializers/vineti_notifications_init.rb)
# The engine had dependencies on platform, specifically for CFG fetch.
# The default source for config in notification-engine was environment.

# Earlier this initializer was run when the notifications engine was loaded
# as part of bundle load. And if there was messages in the queue when the pod
# starts, the subscribers starts picking it up, but those threads did not
# have access to correct configs. AWS, WSO2 creds and other configs were not
# right (or present in ENV source) and so email sending failed.

# Ref: https://vineti.atlassian.net/browse/PLATFORM-4591

# enable_activemq = Vineti::Notifications::Config.instance.feature('vineti_activemq_enable')

# if defined?(Rails::Server) && enable_activemq
#   Vineti::Notifications::ConsumerSeeder.run
# end
