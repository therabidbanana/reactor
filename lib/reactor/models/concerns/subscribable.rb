module Reactor::Subscribable
  extend ActiveSupport::Concern

  class EventHandlerAlreadyDefined < StandardError ; end

  module ClassMethods
    def on_event(*args, &block)
      options = args.extract_options!
      event, method = args
      (Reactor::SUBSCRIBERS[event.to_s] ||= []).push(StaticSubscriberFactory.create(event, method, {source: self}.merge(options), &block))
    end
  end

  class StaticSubscriberFactory

    def self.create(event, method = nil, options = {}, &block)
      source_class          = options[:source] ? options[:source].name : 'Anonymous'

      handler_name = if options[:handler_name]
        options[:handler_name].to_s.camelize
      else
        handler_class_prefix = event == '*' ? 'Wildcard': event.to_s.camelize
        "#{handler_class_prefix}Handler"
      end

      klass = Class.new do
        include Sidekiq::Worker

        class_attribute :method, :delay, :source, :in_memory, :dont_perform

        def perform(data)
          return :__perform_aborted__ if dont_perform && !Reactor::TEST_MODE_SUBSCRIBERS.include?(source)
          event = Reactor::Event.new(data)
          if method.is_a?(Symbol)
            source.delay_for(delay).send(method, event)
          else
            method.call(event)
          end
        end

        def self.perform_where_needed(data)
          if in_memory
            new.perform(data)
          else
            perform_async(data)
          end
        end
      end

      # dynamically define a module namespace based on the subscriber's class name
      unless Reactor::StaticSubscribers.const_defined?(source_class, false)
        Reactor::StaticSubscribers.const_set(source_class, Module.new)
      end

      namespace = Reactor::StaticSubscribers.const_get(source_class, false)

      if namespace.const_defined?(handler_name)
        raise EventHandlerAlreadyDefined.new %{ A Reactor event named #{handler_name} already has been defined on #{namespace}.
            Specify a `:handler_name` option on your subscriber's `on_event` declaration to name this event handler deterministically.
          }
      end

      # add the event handler class to the namespace
      namespace.const_set(handler_name, klass)

      klass.tap do |k|
        k.method = method || block
        k.delay = options[:delay] || 0
        k.source = options[:source]
        k.in_memory = options[:in_memory]
        k.dont_perform = Reactor.test_mode?
      end
    end
  end
end
