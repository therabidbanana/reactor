class Reactor::Subscriber < ActiveRecord::Base
  attr_accessible :event
  attr_accessor :message

  def event=(event)
    write_attribute :event, event.to_s
  end

  def fire(data)
    self.message = Reactor::Event.new(data)
    instance_exec &self.class.on_fire
    self
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

    def subscribes_to(name = nil, data = {})
      #subscribers << name
      #TODO: REMEMBER SUBSCRIBERS so we can define them in code as well as with a row in the DB
      # until then, here's a helper to make it easy to create with random data in postgres
      # total crap I know but whatever
      define_singleton_method :exists! do
        chain = where(event: name)
        data.each do |key, value|
          chain = chain.where("subscribers.data @> ?", "#{key}=>#{value}")
        end
        chain.first_or_create!(data)
      end
    end
  end
end