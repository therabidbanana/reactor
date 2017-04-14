=begin
MailerWorker has a bit more to do than EventWorker. It has to run the event, then if the
output is a Mail::Message or the like it needs to deliver it like ActionMailer would
=end
module Reactor
  module Workers
    class MailerWorker

      include Sidekiq::Worker

      CONFIG = [:source, :action, :async, :delay]

      class_attribute *CONFIG

      def self.configured?
        CONFIG.all? {|field| field.present? }
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
        raise UnconfiguredWorkerError.new unless configured?
        return :__perform_aborted__ unless should_perform?
        event = Reactor::Event.new(data)
        msg = if action.is_a?(Symbol)
          source.send(action, event)
        else
          source.new.instance_exec event, &action
        end

        if msg
          deliver(msg)
        else
          raise UndeliverableMailError.new(
            "#{target.name}##{method_name} returned an undeliverable mail object"
          )
        end
      end

      def deliver(msg)
        if msg.respond_to?(:deliver_now)
          # Rails 4.2/5.0
          msg.deliver_now
        else
          # Rails 3.2/4.0/4.1 + Generic Mail::Message
          msg.deliver
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
