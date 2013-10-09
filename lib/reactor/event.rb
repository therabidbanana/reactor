class Reactor::Event
  include Reactor::OptionallySubclassable
  include Sidekiq::Worker

  attr_accessor :data

  def initialize(data = {})
    self.data = {}.with_indifferent_access
    data.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def perform(name, data)
    data.merge!(fired_at: Time.current, name: name)
    Reactor::Subscriber.where(event: name).each do |subscriber|
      Reactor::Subscriber.delay.fire subscriber.id, data
    end

    #TODO: support more matching?
    Reactor::Subscriber.where(event: '*').each do |s|
      Reactor::Subscriber.delay.fire s.id, data
    end

    ((Reactor::SUBSCRIBERS[name.to_s]  || []) | (Reactor::SUBSCRIBERS['*'] || [])).each {|s| s.perform_async(data) }
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

  class << self
    def perform(name, data)
      new.perform(name, data)
    end

    def publish(name, data = {})
      message = new(data.merge(event: name))

      if message.at.nil?
        perform_async name, message.data
      elsif message.at.future?
        perform_at message.at, name, message.data
      end
    end

    def reschedule(name, data = {})
      scheduled_jobs = Sidekiq::ScheduledSet.new
      job = scheduled_jobs.detect do |job|
        job['class'] == self.name.to_s &&
        job['args'].first == name.to_s &&
        job.score.to_i == data[:was].to_i
      end
      return if job.nil?
      job.delete
      publish(name, data.except(:was)) if data[:at].future?
    end
  end

  private

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
