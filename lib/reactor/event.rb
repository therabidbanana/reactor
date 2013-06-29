class Reactor::Event
  include Reactor::OptionallySubclassable

  def self.publish(name, data = {})
    message = Reactor::Message.new(data.merge(event: name))
    if (message.at)
      delay_until(message.at).process name, message.data
    else
      delay.process name, message.data
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

  def self.process(name, data)
    Reactor::Subscriber.where(event: name.to_s).each do |subscriber|
      Reactor::Subscriber.delay.fire subscriber.id, data
    end

    #TODO: support more matching?
    Reactor::Subscriber.where(event: '*').each do |s|
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
