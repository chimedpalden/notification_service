require_relative '../../../app/helpers/vineti/notifications/pub_sub_upsert_helper'
require_relative '../../fixtures/notification_config_fixture'

namespace :vineti_notifications do
  desc "Configure all notification data, seeds data from yml files to database"
  task :seed => [:environment] do
    Fixtures::NotificationConfigFixture.new.call
  end

  desc "Validates the notification configuration stored for tenant"
  task :validate_config => [:environment] do
    Validators::ConfigValidator.new.call
  end
end
