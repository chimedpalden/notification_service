module Vineti::Notifications
  class Inbound::Operation::ParseTemplate < Trailblazer::Operation
    LIQUID_ERROR = 'Liquid error'.freeze

    step :init
    step :fetch_template_from_publisher!
    step :parse_template_data!
    fail :template_parsing_error!, fail_fast: true
    step :convert_to_type!

    private

    def init(options, **)
      options[:errors] = []
    end

    def fetch_template_from_publisher!(options, publisher:, template_data:, **)
      template = publisher.template
      options[:template_data] = template_data&.deep_dup&.permit!.to_h
      options[:template] = template
    end

    def parse_template_data!(options, template:, template_data:, **)
      renderer = Vineti::Templates::Render.factory(template.data['text_body'])
      options[:parsed_data] = renderer.call!(template_data)
      !options[:parsed_data].match?(LIQUID_ERROR)
    rescue V8::Error => e
      options[:errors] << e.message
      false
    end

    def template_parsing_error!(options, **)
      options[:errors] << { template_parsing: 'Got error while parsing a template' }
      options[:status] = :internal_server_error
    end

    def convert_to_type!(options, parsed_data:, template:, **)
      options[:parsed_data] = case template.data['type']
                              when 'json'
                                JSON.parse options[:parsed_data]
                              else
                                { 'data' => options[:parsed_data] }
                              end
    end
  end
end
