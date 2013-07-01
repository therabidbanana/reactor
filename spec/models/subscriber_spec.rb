require 'spec_helper'

class MySubscriber < Reactor::Subscriber
  attr_accessor :was_called

  on_fire do
    self.was_called = true
  end
end

describe Reactor::Subscriber do

  describe 'fire' do
    subject { MySubscriber.create(event: :you_name_it).fire some: 'random', event: 'data' }

    its(:message) { should be_a Reactor::Event }
    its('message.some') { should == 'random' }

    it 'executes block given' do
      subject.was_called.should be_true
    end
  end

  describe '.subscribes_to class helper' do
    #describe 'ensuring subscriber exists and is tied to event' do
    #  it 'binds 1-1 when name given' do
    #    expect {
    #      MySubscriber.class_eval do
    #        subscribes_to :event_times
    #      end
    #    }.to change { Reactor::Subscriber.count }.by(1)
    #  end
    #
    #  context 'binds to all when star is given' do
    #    after { MySubscriber.destroy_all }
    #
    #    it 'creates new subscriber' do
    #      expect {
    #        MySubscriber.class_eval do
    #          subscribes_to '*'
    #        end
    #      }.to change { Reactor::Subscriber.count }.by(1)
    #    end
    #
    #    it 'doesnt create' do
    #      MySubscriber.where(event: '*').first_or_create!
    #      expect {
    #        MySubscriber.class_eval do
    #          subscribes_to '*'
    #        end
    #      }.to change { Reactor::Subscriber.count }.by(0)
    #    end
    #  end
    #end
  end

  describe 'matcher' do
    it 'can be set to star to bind to all events' do
      MySubscriber.create!(event: '*')
      MySubscriber.any_instance.should_receive(:fire).with({'random' => 'data', 'event' => :this_event})
      Reactor::Event.publish(:this_event, {random: 'data'})
    end
  end
end
