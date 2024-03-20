module Vineti::Notifications::NotificationEmailResponse
  class Base < ::ActiveRecord::Base
    self.table_name = :vineti_notifications_notification_email_responses

    belongs_to :email_log,
               class_name: 'Vineti::Notifications::NotificationEmailLog',
               foreign_key: 'vineti_notifications_notification_email_logs_id'

    has_many :templates, through: :email_log
    has_many :subscribers, through: :email_log
    has_many :events, through: :email_log

    before_save :validate_response

    def initialize(*args)
      if self.class == Vineti::Notifications::NotificationEmailResponse::Base
        raise I18n.t(
          'errors.cannot_instantiate',
          class_name: self.class.name
        )
      end

      super
    end

    def validate_response
      return if response.nil?

      keys = response.keys.map(&:to_sym)
      required_keys = self.class.required_response_keys
      optional_keys = self.class.optional_response_keys

      raise ArgumentError, "#{required_keys - (keys & required_keys)} missing from response" unless (keys & required_keys).sort == required_keys.sort

      invalid_keys = (keys - required_keys - optional_keys)
      raise ArgumentError, "#{invalid_keys} should not be present in response" unless invalid_keys.empty?
    end
  end
end
