module Reactor::Publishable
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_events, if: :persisted?, on: :create
    after_commit :schedule_conditional_events, if: :persisted?, on: [:create, :update]
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
      event = event_data_for_signature(data)
      Reactor::Event.publish name, event
    end
  end

  def reschedule_events
    self.class.events.each do |name, data|
      attr_changed_method = data[:watch] || data[:at]
      if data[:at] && previous_changes[attr_changed_method]
        Reactor::Event.reschedule name,
          data.merge(
            at: send(data[:at]),
            actor: ( data[:actor] ? send(data[:actor]) : self ),
            target: ( data[:target] ? self : nil),
            was: previous_changes[data[:at]].try(:first) || send("#{data[:at]}_was"))
      end
    end
  end

  def schedule_conditional_events
    self.class.events.select { |k,v| v.has_key?(:if) }.each do |name, data|
      event = event_data_for_signature(data)
      need_to_fire = case (ifarg = data[:if])
                       when Proc
                         instance_exec(&ifarg)
                       when Symbol
                         send(ifarg)
                     end
      Reactor::Event.publish name, event if need_to_fire
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
