require 'spec_helper'

class Auction < ActiveRecord::Base
  attr_accessor :we_want_it

  def ring_timeout
    created_at + 30.seconds
  end

  def ring_timeout_was
    created_at + 10.seconds
  end

  publishes :bell
  publishes :ring, at: :ring_timeout, watch: :name
  publishes :conditional_event_on_save, if: -> { we_want_it }
end

class TestSubscriber < Reactor::Subscriber
  @@called = false

  on_fire do
    @@called = true
  end
end

describe Reactor::Eventable do
  describe 'publish' do
    let(:auction) { Auction.create! }

    it 'publishes an event with actor_id and actor_type set as self' do
      auction
      Reactor::Event.should_receive(:publish) do |name, data|
        name.should == :an_event
        data[:what].should == 'the'
        data[:actor].should == auction
      end
      auction.publish(:an_event, {what: 'the'})
    end

    it 'supports immediate events (on create) that get fired once' do
      TestSubscriber.create! event: :bell
      auction
      TestSubscriber.class_variable_get(:@@called).should be_true
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_false
    end

    it 'can fire events onsave for any condition' do
      TestSubscriber.create! event: :conditional_event_on_save
      auction
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_false
      auction.we_want_it = true
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_true
    end
  end
end