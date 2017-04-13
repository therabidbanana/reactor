module Reactor
  module ResourceActionable
    class ShowEvent < ActionEvent
      perform do
        action_event "#{resource_name}_viewed", target: actionable_resource
      end
    end
  end
end
