class Reactor::ResourceActionable::EditEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    action_event "edit_#{resource_name}_form_viewed", target: actionable_resource
  end
end