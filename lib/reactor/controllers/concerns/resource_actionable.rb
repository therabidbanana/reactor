module Reactor
  module ResourceActionable
    extend ActiveSupport::Concern

    included do
      around_filter :infer_basic_action_event
    end

    def infer_basic_action_event
      yield if block_given?

      if (event_descriptor = "Reactor::ResourceActionable::#{action_name.camelize}Event".safe_constantize).present?
        event_descriptor.perform_on self
      else
        action_event "#{resource_name}_#{action_name}"
      end
    end

    module ClassMethods
      def actionable_resource(ivar_name = nil)
        @resource_ivar_name ||= ivar_name
      end

      def nested_resource(ivar_name = nil)
        @nested_resource_ivar_name ||= ivar_name
      end

      # this is so our API controller subclasses can re-use the resource declarations
      def inherited(subclass)
        [:resource_ivar_name, :nested_resource_ivar_name].each do |inheritable_attribute|
          instance_var = "@#{inheritable_attribute}"
          subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
        end
      end
    end

    def actionable_resource; instance_variable_get(self.class.actionable_resource); end
    def nested_resource; self.class.nested_resource && instance_variable_get(self.class.nested_resource); end

    private

    def resource_name
      self.class.actionable_resource.to_s.gsub('@','').underscore
    end
  end
end

require "reactor/controllers/concerns/actions/action_event"
require "reactor/controllers/concerns/actions/new_event"
require "reactor/controllers/concerns/actions/index_event"
require "reactor/controllers/concerns/actions/edit_event"
require "reactor/controllers/concerns/actions/create_event"
require "reactor/controllers/concerns/actions/update_event"
require "reactor/controllers/concerns/actions/destroy_event"
require "reactor/controllers/concerns/actions/show_event"
