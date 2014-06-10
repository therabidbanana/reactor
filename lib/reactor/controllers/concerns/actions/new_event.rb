class Reactor::ResourceActionable::NewEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    action_event "new_#{resource_name}_form_viewed", target: nested_resource
  end
end