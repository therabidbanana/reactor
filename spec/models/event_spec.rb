require 'spec_helper'

describe Reactor::Event do

  it { should have_attribute :type }

  let(:event) { Reactor::Event.for(:user_did_this) }

  describe 'publish' do
    it 'fires the first process and sets message event_id' do
      Reactor::Event.should_receive(:process).with(event.id, 'actor_id' => '1', 'event_id' => event.id, 'event_type' => 'Reactor::Event')
      Reactor::Event.publish(:user_did_this, actor_id: '1')
    end
  end

  describe 'process' do
    it 'fires all subscribers' do
      event.subscribers.create
      Reactor::Subscriber.any_instance.should_receive(:fire).with(actor_id: '1')
      Reactor::Event.process(event.id, actor_id: '1')
    end
  end
end
