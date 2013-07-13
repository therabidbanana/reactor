module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def on_event(event, &callback)
      (Reactor::STATIC_SUBSCRIBERS[event.to_s] ||= []).push(callback)
    end
  end
end