require 'spec_helper'


describe Reactor do
  let(:subscriber) do
    Reactor.in_test_mode do
      Class.new(ActiveRecord::Base) do
        on_event :test_event, -> (event) { self.spy_on_me }
      end
    end
  end

  describe '.test_mode!' do
    it 'sets Reactor into test mode' do
      Reactor.test_mode?.should be_false
      Reactor.test_mode!
      Reactor.test_mode?.should be_true
    end
  end

  context 'in test mode' do
    before { Reactor.test_mode! }
    after  { Reactor.disable_test_mode! }

    it 'subscribers created in test mode are disabled' do
      subscriber.should_not_receive :spy_on_me
      Reactor::Event.publish :test_event
    end

    describe '.with_subscriber_enabled' do
      it 'enables a subscriber during test mode' do
        subscriber.should_receive :spy_on_me
        Reactor.with_subscriber_enabled(subscriber) do
          Reactor::Event.publish :test_event
        end
      end
    end
  end
end
