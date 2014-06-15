class Reactor::ResourceActionable::IndexEvent < Reactor::ResourceActionable::ActionEvent
  perform do
    action_event "#{resource_name.pluralize}_indexed", target: nested_resource
  end
end