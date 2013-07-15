module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def on_event(event, method = nil, &block)
      callback = case method
        when Symbol
          {self => method}
        else
          method
      end
      callback = block if block
      (Reactor::SUBSCRIBERS[event.to_s] ||= []).push(callback)
    end
  end
end