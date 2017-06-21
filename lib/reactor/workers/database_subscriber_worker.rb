module Reactor
  module Workers
    class DatabaseSubscriberWorker

      include Sidekiq::Worker

      def perform(model_id, data)
        return :__perform_aborted__ unless should_perform?
        Reactor::Subscriber.fire(model_id, data)
      end

      def should_perform?
        if Reactor.test_mode?
          Reactor.test_mode_subscriber_enabled? Reactor::Subscriber
        else
          true
        end
      end

    end
  end
end
