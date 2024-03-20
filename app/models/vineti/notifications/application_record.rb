module Vineti
  module Notifications
    class ApplicationRecord < ActiveRecord::Base
      # NOTE:
      # this file will not be reloaded in development due to
      # explicit require in initializers/activemq

      self.abstract_class = true
    end
  end
end
