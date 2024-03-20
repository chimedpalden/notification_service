# frozen_string_literal: true

module Vineti::Notifications
  class TemplatesController < Vineti::Notifications::ApplicationController
    before_action :fetch_template!, only: %i[update destroy show]

    def index
      render_result(Vineti::Notifications::Template.all.order('id'))
    end

    def show
      render_result(@template)
    end

    def create
      template = Vineti::Notifications::Template.create!(template_params)

      render_result(template)
    end

    def update
      @template.update!(template_params)

      render_result(@template)
    end

    def destroy
      render_result(@template.destroy!)
    end

    private

    def template_params
      if params.dig(:template, :data, :template_type).present?
        ActiveSupport::Deprecation.warn("'template_type' attribute is depricated. This will be an Invalid Configuration in the future")
      end
      params.require(:template).permit(:template_id, data: %i[subject text_body html_body template_type], default_variables: {})
    end

    def fetch_template!
      @template ||= Vineti::Notifications::Template.find_by!(params.permit(:template_id))
    end

    def render_result(result)
      render jsonapi: result,
             include: [template: :subscribers],
             class: { 'Vineti::Notifications::Template': TemplateSerializer }
    end
  end
end
