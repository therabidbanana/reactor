require "reactor/version"
require "reactor/models/concerns/eventable"
require "reactor/models/concerns/optionally_subclassable"
require "reactor/models/subscriber"
require "reactor/event"

module Reactor

end

ActiveRecord::Base.send(:include, Reactor::Eventable)
