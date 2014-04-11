module Reactor::Subscribable
  extend ActiveSupport::Concern

  module ClassMethods
    def on_event(*args, &block)
      options = args.extract_options!
      event, method = args
      (Reactor::SUBSCRIBERS[event.to_s] ||= []).push(StaticSubscriberFactory.create(event, method, {source: self}.merge(options), &block))
    end
  end

  class StaticSubscriberFactory

    def self.create(event, method = nil, options = {}, &block)
      handler_class_prefix = event == '*' ? 'Wildcard': event.to_s.camelize
      i = 0
      begin
        new_class = "#{handler_class_prefix}Handler#{i}"
        i+= 1
      end while Reactor::StaticSubscribers.const_defined?(new_class)

      eval %Q{
        class Reactor::StaticSubscribers::#{new_class}
          include Sidekiq::Worker

          cattr_accessor :method, :delay, :source, :in_memory

          def perform(data)
            event = Reactor::Event.new(data)
            if @@method.is_a?(Symbol)
              @@source.delay_for(@@delay).send(@@method, event)
            else
              @@method.call(event)
            end
          end

          def self.perform_where_needed(data)
            if @@in_memory
              new.perform(data)
            else
              perform_async(data)
            end
          end
        end
      }

      new_class = "Reactor::StaticSubscribers::#{new_class}".constantize
      new_class.method = method || block
      new_class.delay = options[:delay] || 0
      new_class.source = options[:source]
      new_class.in_memory = options[:in_memory]
      new_class
    end
  end
end