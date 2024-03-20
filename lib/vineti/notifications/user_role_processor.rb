# frozen_string_literal: true

module Vineti::Notifications
  class UserRoleProcessor
    def self.fetch_users_from_role(data)
      new_list = data.clone
      %w[to_addresses cc_addresses bcc_addresses].each do |key|
        next if data[key].blank?

        roles = data[key].reject { |add| URI::MailTo::EMAIL_REGEXP.match? add }
        email_addresses = data[key].select { |add| URI::MailTo::EMAIL_REGEXP.match? add }
        result = fetch_user_emails(roles)
        result.success? ? email_addresses.concat(result[:user_emails].to_a) : (raise StandardError, result[:errors])
        new_list[key] = email_addresses
      end
      new_list
    end

    # Created this method so that we can add specs for this file
    # We can mock this method to return required response and continue with
    # next operations

    # NOOOO: More coupling to the vineti-platform. UserRole::Operation::UserEmails
    # is not a part of vineti-notifications.
    # TODO: vineti_notifications: Remove direct call and use API instead
    def self.fetch_user_emails(roles)
      ::UserRole::Operation::UserEmails.call(params: { user_roles: roles })
    end

    private_class_method :fetch_user_emails
  end
end
