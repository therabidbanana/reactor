module Reactor
  module ResourceActionable
    class DestroyEvent < ActionEvent
      perform do
        action_event "#{resource_name}_destroyed", last_snapshot: actionable_resource.as_json
      end
    end
  end
end
