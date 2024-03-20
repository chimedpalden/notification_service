class ApplicationRecord < ActiveRecord::Base
  # NOTE:
  # this file/class will not be reloaded in development due to
  # explicit require in initializers/activemq

  self.abstract_class = true
end
