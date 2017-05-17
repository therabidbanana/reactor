require 'spec_helper'

class DbSubscriber < Reactor::Subscriber
  attr_accessor :was_called

  on_fire do
    self.was_called = true
  end
end

describe Reactor::Workers::DatabaseSubscriberWorker do
  let(:event_name) { :fire_db_subscriber }
  let(:data) { Hash[unused: :data] }
  let!(:db_subscriber) { DbSubscriber.create!(event_name: event_name) }

  let(:instance) { described_class.new }

  describe '#perform' do

    subject { instance.perform(db_subscriber.id, data) }

    context 'when should_perform? is false' do
      before { allow_any_instance_of(DbSubscriber).to receive(:should_perform?).and_return(false) }

      it { is_expected.to eq(:__perform_aborted__) }
    end

    context 'when should_perform? is true' do
      before do
        allow(instance).to receive(:should_perform?).and_return(true)
      end

      it 'fires subscriber' do
        expect(Reactor::Subscriber).to receive(:fire).with(db_subscriber.id, data)
        subject
      end
    end

  end

  describe '#should_perform?' do
    subject { instance.should_perform? }

    context 'in test mode' do
      context 'when subscriber is not enabled' do
        it { is_expected.to eq(false) }
      end

      context 'when subscriber is enabled' do
        it 'should equal true' do
          Reactor.with_subscriber_enabled Reactor::Subscriber do
            expect(subject).to eq(true)
          end
        end
      end
    end

    context 'outside test mode' do
      before do
        allow(Reactor).to receive(:test_mode?).and_return(false)
      end

      it { is_expected.to eq(true) }
    end
  end

end
