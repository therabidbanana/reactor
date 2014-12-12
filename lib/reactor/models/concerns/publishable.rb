module Reactor::Publishable
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_events, if: :persisted?, on: :create
    after_commit :reschedule_events_on_update, if: :persisted?, on: :update
  end

  def publish(name, data = {})
    Reactor::Event.publish(name, data.merge(actor: self) )
  end

  def reschedule_events
    self.class.events.each do |name, data|
      reschedule(name, data)
    end
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

  def reschedule_events_on_update
    self.class.events.each do |name, data|
      attr_changed_method = data[:watch] || data[:at]
      if previous_changes[attr_changed_method]
        reschedule(name, data)
      end
    end
  end

  def reschedule(name, data)
    if data[:at]
      Reactor::Event.reschedule name,
        data.merge(
            at: send(data[:at]),
            actor: ( data[:actor] ? send(data[:actor]) : self ),
            target: ( data[:target] ? self : nil),
            was: previous_changes[data[:at]].try(:first) || send("#{data[:at]}_was"))
    end
  end

  def schedule_events
    self.class.events.each do |name, data|
      event = event_data_for_signature(data)
      Reactor::Event.publish name, event
    end
  end

  def event_data_for_signature(signature)
    signature.merge(
        actor: (signature[:actor] ? send(signature[:actor]) : self),
        target: (signature[:target] ? self : nil),
        at: (signature[:at] ? send(signature[:at]) : nil)
    ).except(:watch, :if)
  end
end
