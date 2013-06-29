require 'spec_helper'

describe Reactor::Event do

  let(:event_name) { :user_did_this }

  describe 'publish' do
    it 'fires the first process and sets message event_id' do
      Reactor::Event.should_receive(:process).with(event_name, 'actor_id' => '1', 'event' => :user_did_this)
      Reactor::Event.publish(:user_did_this, actor_id: '1')
    end
  end

  describe 'process' do
    it 'fires all subscribers' do
      Reactor::Subscriber.create(event: :user_did_this)
      Reactor::Subscriber.any_instance.should_receive(:fire).with(actor_id: '1')
      Reactor::Event.process(event_name, actor_id: '1')
    end
  end
end
