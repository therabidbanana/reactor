module Reactor
  module ResourceActionable
    class NewEvent < ActionEvent
      perform do
        action_event "new_#{resource_name}_form_viewed", target: nested_resource
      end
    end
  end
end
