module Reactor
  module Workers
    class DelayedWorker < EventWorker

      CONFIG = [:source, :action, :delay, :async]

      class_attribute *CONFIG

      def self.configured?
        CONFIG.all? {|field| field.present? }
      end

      def self.perform_where_needed(data)
        if async
          perform_in(delay, data)
          source
        else
          new.perform(data)
        end
      end

      def configured?
        self.class.configured?
      end

      def perform(data)
        raise UnconfiguredWorkerError.new unless configured?
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

    end
  end
end
