module Reactor::Eventable
  extend ActiveSupport::Concern

  included do
    after_create :schedule_events
    after_update :reschedule_events
  end

  def publish(name, data = {})
    Reactor::Event.publish(name, data.merge(actor: self) )
  end

  module ClassMethods
    def publishes(name, data = {})
      events[name] = data
    end

    def events
      @events ||= {}
    end
  end

  private

  def schedule_events
    self.class.events.each do |name, data|
      Reactor::Event.delay.publish name, data.merge(
        at: send(data[:at]), actor: self
      ).except(:watch)
    end
  end

  def reschedule_events
    self.class.events.each do |name, data|
      if send("#{data[:watch] || data[:at]}_changed?")
        Reactor::Event.delay.reschedule name,
          at: send(data[:at]),
          actor: self,
          was: send("#{data[:at]}_was")
      end
    end
  end
end