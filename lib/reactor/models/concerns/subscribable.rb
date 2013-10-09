module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def on_event(event, method = nil, options = {}, &block)
      (Reactor::SUBSCRIBERS[event.to_s] ||= []).push(StaticSubscriberFactory.create event, method, {source: self}.merge(options), &block)
    end
  end

  class StaticSubscriberFactory

    def self.create(event, method = nil, options = {}, &block)
      handler_class_prefix = event == '*' ? 'Wildcard': event.to_s.camelize
      new_class = "Reactor::StaticSubscribers::#{handler_class_prefix}Handler#{Reactor::SUBSCRIBERS[event.to_s].size}"

      eval %Q{
        class #{new_class}
          include Sidekiq::Worker

          cattr_accessor :method, :delay, :source

          def perform(data)
            event = Reactor::Event.new(data)
            if @@method.is_a?(Symbol)
              @@source.delay_for(@@delay).send(@@method, event)
            else
              @@method.call(event)
            end
          end
        end
      }

      new_class = new_class.constantize
      new_class.method = method || block
      new_class.delay = options[:delay] || 0
      new_class.source = options[:source]
      new_class
    end
  end
end