class Reactor::Event
  include Reactor::OptionallySubclassable
  include Sidekiq::Worker

  class UnserializableModelKeysIncluded < StandardError; end;

  attr_accessor :data

  def initialize(data = {})
    self.data = {}.with_indifferent_access
    data.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def perform(name, data)
    data.merge!(fired_at: Time.current, name: name)
    fire_database_driven_subscribers(data, name)
    fire_block_subscribers(data, name)
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
      enforce_serializable_model_keys!(data)

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

    private

    def enforce_serializable_model_keys!(event_signature)
      event_signature = event_signature.stringify_keys
      serializable_models = event_signature.keys.map(&:to_s).select { |k| k.end_with?('_id') || k.end_with?('_type') }
      .map { |k| k.gsub(/_id\Z/, '') }
      .map { |k| k.gsub(/_type\Z/, '') }
      .uniq

      serializable_models.each do |model_relation_name|
        raise UnserializableModelKeysIncluded, "#{model_relation_name}_type is missing corresponding _id key" if event_signature["#{model_relation_name}_id"].blank?
        raise UnserializableModelKeysIncluded, "#{model_relation_name}_id is missing corresponding _type key" if event_signature["#{model_relation_name}_type"].blank?

      end
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

  def fire_database_driven_subscribers(data, name)
    #TODO: support more matching?
    Reactor::Subscriber.where(event_name: [name, '*']).each do |subscriber|
      Reactor::Subscriber.delay.fire subscriber.id, data
    end
  end

  def fire_block_subscribers(data, name)
    ((Reactor::SUBSCRIBERS[name.to_s] || []) | (Reactor::SUBSCRIBERS['*'] || [])).each { |s| s.perform_where_needed(data) }
  end
end
