# frozen_string_literal: true

class SubscriptionResponse
  attr_reader :response

  delegate :arn, :subscriptions, to: :response

  def initialize(response)
    @response = response
  end

  def id
    'current'
  end

  def list
    subscriptions.map do |subscription|
      {
        subscription_arn: subscription.subscription_arn,
        topic_arn: subscription.topic_arn,
        endpoint: subscription.endpoint,
        protocol: subscription.protocol,
        owner: subscription.owner,
      }
    end
  end
end
