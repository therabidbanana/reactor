class Reactor::Subscriber < ActiveRecord::Base
  belongs_to :event
  attr_accessible :event_id, :event, :matcher
  attr_accessor :message


  def fire(data)
    self.message = Reactor::Message.new(data)
    instance_exec &self.class.on_fire
    self
  end

  def delay_amount
    self.class.delay_amount
  end

  class << self
    def on_fire(&block)
      if block
        @fire_block = block
      end
      @fire_block
    end

    def fire(subscriber_id, data)
      Reactor::Subscriber.find(subscriber_id).fire data
    end

    def subscribes_to(name, delay: nil)
      @delay_amount = delay
      if Reactor::Event.table_exists? && Reactor::Subscriber.table_exists?
        if name == '*'
          where(type: self.to_s, matcher: '*').first_or_create!
        else
          event = Reactor::Event.for(name)
          @instance = where(event_id: event.id).first_or_create!
        end
      end
    end

    def delay_amount
      @delay_amount
    end

    def instance
      @instance
    end
  end
end