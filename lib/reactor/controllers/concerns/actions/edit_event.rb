module Reactor
  module ResourceActionable
    class EditEvent < ActionEvent
      perform do
        action_event "edit_#{resource_name}_form_viewed", target: actionable_resource
      end
    end
  end
end
