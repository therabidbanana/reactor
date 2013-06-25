class Reactor::Message
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