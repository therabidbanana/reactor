=begin
EventWorker is an abstract worker for handling events defined by on_event.
You can create handlers by subclassing and redefining the configuration class
methods, or by using Reactor::Workers::EventWorker.dup and overriding the
methods on the new class.
=end
module Reactor
  module Workers
    class EventWorker

      include Sidekiq::Worker

      CONFIG = [:source, :action, :delay, :async]

      class_attribute *CONFIG

      def self.configured?
        CONFIG.all? {|field| field.present? }
      end

      def configured?
        self.class.configured?
      end

      def perform(data)
        raise UnconfiguredWorkerError.new unless configured?
        return :__perform_aborted__ unless should_perform?
        event = Reactor::Event.new(data)
        if action.is_a?(Symbol)
          source.delay_for(delay).send(action, event)
        else
          action.call(event)
        end
      end

      def self.perform_where_needed(data)
        if async
          perform_async(data)
        else
          new.perform(data)
        end
      end

      def should_perform?
        if Reactor.test_mode?
          Reactor.test_mode_subscriber_enabled? source
        else
          true
        end
      end
    end
  end
end
