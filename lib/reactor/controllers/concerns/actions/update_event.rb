class Reactor::ResourceActionable::UpdateEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    if actionable_resource.valid?
      action_event "#{resource_name}_updated",
                   target: actionable_resource,
                   changes: actionable_resource.previous_changes.as_json
    else
      action_event "#{resource_name}_update_failed",
                   target: actionable_resource,
                   errors: actionable_resource.errors.as_json,
                   attributes: params[resource_name]
    end
  end
end