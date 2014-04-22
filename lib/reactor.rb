require "reactor/version"
require "reactor/models/concerns/publishable"
require "reactor/models/concerns/subscribable"
require "reactor/models/concerns/optionally_subclassable"
require "reactor/models/subscriber"
require "reactor/event"

module Reactor
  SUBSCRIBERS = {}
  TEST_MODE_SUBSCRIBERS = Set.new
  @@test_mode = false

  module StaticSubscribers
  end

  def self.test_mode?
    @@test_mode
  end

  def self.test_mode!
    @@test_mode = true
  end

  def self.disable_test_mode!
    @@test_mode = false
  end

  def self.in_test_mode
    test_mode!
    (yield if block_given?).tap { disable_test_mode! }
  end

  def self.enable_test_mode_subscriber(klass)
    TEST_MODE_SUBSCRIBERS << klass
  end

  def self.disable_test_mode_subscriber(klass)
    TEST_MODE_SUBSCRIBERS.delete klass
  end

  def self.with_subscriber_enabled(klass)
    enable_test_mode_subscriber klass
    yield if block_given?
    disable_test_mode_subscriber klass
  end
end

ActiveRecord::Base.send(:include, Reactor::Publishable)
ActiveRecord::Base.send(:include, Reactor::Subscribable)
