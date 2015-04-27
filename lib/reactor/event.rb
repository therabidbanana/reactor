class Reactor::Event < ActiveJob::Base
  attr_accessor :data

  def initialize(data = {})
    super(data)
    self.data = {}.with_indifferent_access
    data.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def perform(data)
    data = data.with_indifferent_access
    data.merge!(fired_at: Time.current.to_i)
    fire_database_driven_subscribers(data)
    fire_block_subscribers(data)
  end

  def method_missing(method, *args)
    if method.to_s.include?('=')
      try_setter(method, *args)
    else
      try_getter(method)
    end
  end

  def self.publish(name, data = {})
    message = new(data.merge(name: name.to_s))

    if message.at
      set(wait_until: message.at).perform_later message.data
    else
      perform_later message.data
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

  def fire_database_driven_subscribers(data)
    #TODO: support more matching?
    Reactor::Subscriber.where(event_name: [data[:name], '*']).each do |subscriber|
      Reactor::Jobs::SubscriberJob.perform_later subscriber, data
    end
  end

  def fire_block_subscribers(data)
    ((Reactor::SUBSCRIBERS[data[:name].to_s] || []) | (Reactor::SUBSCRIBERS['*'] || [])).each { |s| s.perform_where_needed(data) }
  end
end
