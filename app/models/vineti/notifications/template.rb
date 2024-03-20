module Vineti
  module Notifications
    class Template < ApplicationRecord
      has_paper_trail
      has_many :subscribers,
               class_name: 'Vineti::Notifications::Subscriber',
               foreign_key: 'vineti_notifications_templates_id'

      validate :valid_template_data?
      validates :template_id, presence: true, uniqueness: { message: 'template id is already taken' }

      def data=(template_config)
        unless template_config['type'].blank?
          template_config['text_body'] = template_config['text_body'].send("to_#{template_config['type']}")
        end
        super(template_config)
      end

      private

      def valid_template_data?
        keys = ['text_body']
        keys.push('subject') unless data['type'] == 'json'

        keys.each do |key|
          errors.add(:data, "Missing value for #{key.split('_').map(&:titleize).join(' ')}.") if data[key].blank?
        end
      end
    end
  end
end
