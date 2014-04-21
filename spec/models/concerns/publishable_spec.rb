require 'spec_helper'

class Pet < ActiveRecord::Base
end

class Auction < ActiveRecord::Base
  attr_accessor :we_want_it
  belongs_to :pet

  def ring_timeout
    start_at + 30.seconds
  end

  def ring_timeout_was
    previous_changes[:start_at][0] + 30.seconds
  end

  publishes :bell
  publishes :ring, at: :ring_timeout, watch: :start_at
  publishes :begin, at: :start_at, additional_info: 'curtis was here'
  publishes :conditional_event_on_save, if: -> { we_want_it }
  publishes :woof, actor: :pet, target: :self
end

class TestSubscriber < Reactor::Subscriber
  @@called = false

  on_fire do
    @@called = true
  end
end

describe Reactor::Publishable do
  before { TestSubscriber.destroy_all }
  describe 'publish' do
    let(:pet) { Pet.create! }
    let(:auction) { Auction.create!(pet: pet, start_at: DateTime.new(2012,12,21)) }

    it 'publishes an event with actor_id and actor_type set as self' do
      auction
      Reactor::Event.should_receive(:publish) do |name, data|
        name.should == :an_event
        data[:what].should == 'the'
        data[:actor].should == auction
      end
      auction.publish(:an_event, {what: 'the'})
    end

    it 'publishes an event with provided actor and target methods' do
      Reactor::Event.should_receive(:publish) do |name, data|
        name.should == :woof
        data[:actor].should == pet
      end
      auction
    end

    it 'reschedules an event when the :at time changes' do
      start_at = auction.start_at
      new_start_at = start_at + 1.week
      Reactor::Event.should_receive(:reschedule).with :ring, anything
      Reactor::Event.should_receive(:reschedule).with :begin,
        hash_including(
          at: new_start_at,
          actor: auction,
          was: start_at,
          additional_info: 'curtis was here'
        )
      auction.start_at = new_start_at
      auction.save!
    end

    it 'reschedules an event when the :watch field changes' do
      ring_time = auction.ring_timeout
      new_start_at = auction.start_at + 1.week
      new_ring_time = new_start_at + 30.seconds
      Reactor::Event.should_receive(:reschedule).with :begin, anything
      Reactor::Event.should_receive(:reschedule).with :ring,
        hash_including(
          at: new_ring_time,
          actor: auction,
          was: ring_time
        )
      auction.start_at = new_start_at
      auction.save!
    end

    it 'supports immediate events (on create) that get fired once' do
      TestSubscriber.create! event_name: :bell
      auction
      TestSubscriber.class_variable_get(:@@called).should be_true
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_false
    end

    it 'does not publish an event scheduled for the past' do
      TestSubscriber.create! event_name: :begin
      auction
      TestSubscriber.class_variable_get(:@@called).should be_false
    end

    it 'does publish an event scheduled for the future' do
      TestSubscriber.create! event_name: :begin
      Auction.create!(pet: pet, start_at: Time.current + 1.week)

      TestSubscriber.class_variable_get(:@@called).should be_true
    end

    it 'can fire events onsave for any condition' do
      TestSubscriber.create! event_name: :conditional_event_on_save
      auction
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_false
      auction.start_at = 2.days.from_now
      auction.we_want_it = true
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_true
    end
  end
end
