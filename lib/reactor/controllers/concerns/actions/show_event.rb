class Reactor::ResourceActionable::ShowEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    action_event "#{resource_name}_viewed", target: actionable_resource
  end
end
