require "reactor/version"
require "reactor/models/concerns/publishable"
require "reactor/models/concerns/subscribable"
require "reactor/models/concerns/optionally_subclassable"
require "reactor/models/subscriber"
require "reactor/event"

module Reactor
  SUBSCRIBERS = {}
  module StaticSubscribers
  end
end

ActiveRecord::Base.send(:include, Reactor::Publishable)
ActiveRecord::Base.send(:include, Reactor::Subscribable)