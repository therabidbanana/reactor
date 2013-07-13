module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def subscribes_to(event, &callback)
      (Reactor::STATIC_SUBSCRIBERS[event.to_s] ||= []).push(callback)
    end
  end
end