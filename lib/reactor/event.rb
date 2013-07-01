class Reactor::Event
  include Reactor::OptionallySubclassable

  attr_accessor :data

  def initialize(data = {})
    self.data = {}.with_indifferent_access
    data.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def method_missing(method, *args)
    if method.to_s.include?('=')
      try_setter(method, *args)
    else
      try_getter(method)
    end
  end

  def to_s
    name
  end

  def self.publish(name, data = {})
    message = new(data.merge(event: name))
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

  def self.scheduled_jobs(options = {})
    Sidekiq.redis do |r|
      from = options[:from] ? options[:from].to_f.to_s : '-inf'
      to = options[:to] ? options[:to].to_f.to_s : '+inf'
      r.zrangebyscore('schedule', from, to).map{|job| MultiJson.decode(job)}
    end
  end

  def self.remove_scheduled_job(job)
    Sidekiq.redis { |r| r.zrem 'schedule', MultiJson.encode(job) }
  end

  def try_setter(method, object, *args)
    if object.is_a? ActiveRecord::Base
      send("#{method}_id", object.id)
      send("#{method}_type", object.class.to_s)
    else
      data[method.to_s.gsub('=','')] = object
    end
  end

  def try_getter(method)
    if polymorphic_association? method
      initialize_polymorphic_association method
    elsif data.has_key?(method)
      data[method]
    end
  end

  def polymorphic_association?(method)
    data.has_key?("#{method}_type")
  end

  def initialize_polymorphic_association(method)
    data["#{method}_type"].constantize.find(data["#{method}_id"])
  end
end
