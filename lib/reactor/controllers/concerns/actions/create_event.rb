class Reactor::ResourceActionable::CreateEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    if actionable_resource.valid?
      action_event "#{resource_name}_created",
                   target: actionable_resource,
                   attributes: params[resource_name]
    else
      action_event "#{resource_name}_create_failed",
                   errors: actionable_resource.errors.as_json,
                   attributes: params[resource_name],
                   target: nested_resource
    end
  end
end