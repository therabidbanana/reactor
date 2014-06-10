class Reactor::ResourceActionable::DestroyEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    action_event "#{resource_name}_destroyed", last_snapshot: actionable_resource.as_json
  end
end