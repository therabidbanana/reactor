module Reactor::Eventable
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_events, if: :persisted?, on: :create
    after_commit :reschedule_events, if: :persisted?, on: :update
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
      data = data.merge(
          at: ( data[:at] ? send(data[:at]) : nil), actor: self
      ).except(:watch)
      Reactor::Event.delay.publish name, data
    end
  end

  def reschedule_events
    self.class.events.each do |name, data|
      if data[:at] && send("#{data[:watch] || data[:at]}_changed?")
        Reactor::Event.delay.reschedule name,
          at: send(data[:at]),
          actor: self,
          was: send("#{data[:at]}_was")
      end
    end
  end
end