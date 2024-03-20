# frozen_string_literal: true

require 'aws-sdk-ses'

class Ses
  attr_reader :client

  def initialize
    @client = get_client
  end

  def send_email(source:, destination:, message:)
    client.send_email(source: source, destination: destination, message: message)
  end

  private

  # This prevents problems when the AWS SES Credentials
  # are not in certain environments
  def get_client
    if disable_ses?
      ApplicationMailerService.new
    else
      Aws::SES::Client.new(
        access_key_id: Vineti::Notifications::Config.instance.fetch('aws_ses_access_key_id'),
        secret_access_key: Vineti::Notifications::Config.instance.fetch('aws_ses_secret_access_key'),
        region: Vineti::Notifications::Config.instance.fetch('aws_ses_region')
      )
    end
  end

  # Vineti::Notifications::Config.instance will usually return strings. The string
  # should be a boolean so it must be casted.
  def disable_ses?
    Vineti::Notifications::Config.instance.fetch('disable_ses')
  end
end
