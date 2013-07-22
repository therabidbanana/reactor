module Reactor::Publishable
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
      event = data.merge(
          actor: ( data[:actor] ? send(data[:actor]) : self ),
          target: ( data[:target] ? self : nil),
          at: ( data[:at] ? send(data[:at]) : nil)
      ).except(:watch, :if)
      need_to_fire = case (ifarg = data[:if])
                       when Proc
                         instance_exec &ifarg
                       when Symbol
                         send(ifarg)
                       else
                         true
                     end
      Reactor::Event.publish name, event if need_to_fire
    end
  end

  def reschedule_events
    self.class.events.each do |name, data|
      attr_changed_method = "#{data[:watch] || data[:at]}_changed?"
      if data[:at] && respond_to?(attr_changed_method) && send(attr_changed_method)
        Reactor::Event.reschedule name,
          at: send(data[:at]),
          actor: ( data[:actor] ? send(data[:actor]) : self ),
          target: ( data[:target] ? self : nil),
          was: send("#{data[:at]}_was")
      end
      if data[:if]
        need_to_fire = case (ifarg = data[:if])
                         when Proc
                           instance_exec &ifarg
                         when Symbol
                           send(ifarg)
                       end
        Reactor::Event.publish name, actor: self if need_to_fire
      end
    end
  end
end