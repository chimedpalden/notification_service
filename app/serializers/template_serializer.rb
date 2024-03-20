# frozen_string_literal: true

class TemplateSerializer < JSONAPI::Serializable::Resource
  type 'template'

  attributes :template_id, :default_variables, :data, :subscribers
end
