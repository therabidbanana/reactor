require 'spec_helper'

Reactor.in_test_mode do
  class SomeClass
    include Reactor::Subscribable
    on_event :test_event, -> (event) { self.spy_on_me }
  end
end

describe Reactor do
  let(:subscriber) { SomeClass }

  describe '.test_mode!' do
    it 'sets Reactor into test mode' do
      expect(Reactor.test_mode?).to be_falsey
      Reactor.test_mode!
      expect(Reactor.test_mode?).to be_truthy
    end
  end

  context 'in test mode' do
    before { Reactor.test_mode! }
    after  { Reactor.disable_test_mode! }

    it 'subscribers created in test mode are disabled' do
      expect(subscriber).not_to receive :spy_on_me
      Reactor::Event.publish :test_event
    end

    describe '.with_subscriber_enabled' do
      it 'enables a subscriber during test mode' do
        expect(subscriber).to receive :spy_on_me
        Reactor.with_subscriber_enabled(subscriber) do
          Reactor::Event.publish :test_event
        end
      end
    end
  end
end
