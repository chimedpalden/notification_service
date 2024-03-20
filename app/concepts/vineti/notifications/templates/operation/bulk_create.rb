module Vineti::Notifications
  class Templates::Operation::BulkCreate
    VALID_TEMPLATE_KEYS = %w[template_id data deeplinks default_variables].freeze
    VALID_DATA_KEYS = %w[subject text_body html_body type template_type].freeze

    def self.call(templates:)
      if valid_params?(templates)
        upsert_templates(templates)
        { status: 201 }
      else
        { errors: { message: 'content is invalid' }, status: 422 }
      end
    end

    def self.valid_params?(templates)
      templates.is_a?(Array) && templates.all? do |template|
        valid_keys = template.keys&.all? { |key| VALID_TEMPLATE_KEYS.include? key }
        valid_data_keys = template['data']&.keys&.all? do |key|
          ActiveSupport::Deprecation.warn("'template_type' attribute is depricated. This will be an Invalid Configuration in the future") if key == 'template_type'
          VALID_DATA_KEYS.include? key
        end
        valid_default_variables = (template['default_variables'].nil? || (template['default_variables'].is_a? Hash))
        valid_deeplinks = (template['deeplinks'].nil? || (template['deeplinks'].is_a? Hash))
        valid_keys && valid_data_keys && valid_default_variables && valid_deeplinks
      end
    end

    private_class_method def self.upsert_templates(templates)
      template_name = nil
      templates.each do |template_details|
        template_name = template_details['template_id']
        template = Vineti::Notifications::Template.find_by(template_id: template_details['template_id'])
        if template.present?
          template.update!(template_details.except('template_id'))
          Rails.logger.info "Updated email template with name #{template_details['template_id']}"
          next
        end
        template = Vineti::Notifications::Template.create!(template_details)
        Rails.logger.info "Created an email template with name #{template.template_id} and email_body #{template_details}..."
      end
    rescue StandardError => e
      Rails.logger.fatal "Got error #{e.message} while creating/updating an template with name #{template_name}!!!"
      raise e
    end
  end
end
