module Reactor::Eventable
  extend ActiveSupport::Concern

  included do
    after_create :schedule_events
    after_update :reschedule_events
  end

  def publish(name, data = {})
    Reactor::Event.publish(name, data.merge(actor_id: self.id, actor_type: self.class.to_s) )
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
      at: send(data[:at]), actor_id: self.id
      ).except(:watch)
    end
  end

  def reschedule_events
    self.class.events.each do |name, data|
      if send("#{data[:watch] || data[:at]}_changed?")
        Reactor::Event.delay.reschedule name,
        at: send(data[:at]),
        actor_id: self.id,
        was: send(data[:at], was: true)
      end
    end
  end
end