module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def on_event(event, method = nil, options = {}, &block)
      callback = {method: (method || block), options: {delay: 0}.merge(options)}
      callback.merge!(source: self) if method.is_a? Symbol
      (Reactor::SUBSCRIBERS[event.to_s] ||= []).push(callback)
    end
  end
end