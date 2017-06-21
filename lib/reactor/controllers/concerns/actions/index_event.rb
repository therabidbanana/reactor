module Reactor
  module ResourceActionable
    class IndexEvent < ActionEvent
      perform do
        action_event "#{resource_name.pluralize}_indexed", target: nested_resource
      end
    end
  end
end
