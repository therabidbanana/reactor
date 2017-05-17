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

      CONFIG = [:source, :action, :async, :delay]

      class_attribute *CONFIG

      def self.configured?
        CONFIG.all? {|field| !self.send(field).nil? }
      end

      def self.perform_where_needed(data)
        if delay > 0
          perform_in(delay, data)
        elsif async
          perform_async(data)
        else
          new.perform(data)
        end
        source
      end

      def configured?
        self.class.configured?
      end

      def perform(data)
        raise_unconfigured! unless configured?
        return :__perform_aborted__ unless should_perform?
        event = Reactor::Event.new(data)
        if action.is_a?(Symbol)
          source.send(action, event)
        else
          action.call(event)
        end
      end

      def should_perform?
        if Reactor.test_mode?
          Reactor.test_mode_subscriber_enabled? source
        else
          true
        end
      end

      private

      def raise_unconfigured!
        settings = Hash[CONFIG.map {|s| [s, self.class.send(s)] }]
        raise UnconfiguredWorkerError.new(
          "#{self.class.name} is not properly configured! Here are the settings: #{settings}"
        )
      end
    end
  end
end
