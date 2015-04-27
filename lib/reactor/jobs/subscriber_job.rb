class Reactor::Jobs::SubscriberJob < ActiveJob::Base
  def perform(subscriber, data)
    subscriber.fire
  end
end
