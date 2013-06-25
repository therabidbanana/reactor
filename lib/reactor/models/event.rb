class Reactor::Event < ActiveRecord::Base
  include Reactor::OptionallySubclassable
  has_many :subscribers

  attr_accessible :type

  validates_uniqueness_of :type

  def type=(type)
    write_attribute :type, type.to_s.camelize
  end

  def self.for(type)
    where(type: type.to_s.camelize).first_or_create
  end

  def self.publish(type, data = {})
    message = Reactor::Message.new(data)
    event = self.for(type)
    if (message.at)
      delay_until(message.at).process event.id, message.data
    else
      delay.process event.id, message.data
    end
  end

  def self.reschedule(name, data = {})
    job = scheduled_jobs.detect do |job|
      job['class'] == name.to_s.camelize && job['at'].to_i == data[:was].to_i
    end
    remove_scheduled_job job if job
    delay.publish(name, data.except(:was)) if data[:at].future?
  end

  def to_s
    name
  end

  def self.process(event_id, data)
    event = find(event_id)

    event.subscribers.each do |subscriber|
      Reactor::Subscriber.delay.fire subscriber.id, data
    end

    Reactor::Subscriber.where(matcher: '*').each do |s|
      Reactor::Subscriber.delay.fire s.id, data
    end
  end

  private

  def self.scheduled_jobs
    Sidekiq.redis do |r|
      from = options[:from] ? options[:from].to_f.to_s : '-inf'
      to = options[:to] ? options[:to].to_f.to_s : '+inf'
      r.zrangebyscore('schedule', from, to).map{|job| MultiJson.decode(job)}
    end
  end

  def self.remove_scheduled_job(job)
    Sidekiq.redis { |r| r.zrem 'schedule', MultiJson.encode(job) }
  end
end
