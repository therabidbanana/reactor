require 'spec_helper'

class Pet < ActiveRecord::Base
end

class Auction < ActiveRecord::Base
  attr_accessor :we_want_it, :arbitrary_date
  belongs_to :pet

  def ring_timeout
    created_at + 30.seconds
  end

  def ring_timeout_was
    created_at + 10.seconds
  end

  publishes :bell
  publishes :ring, at: :ring_timeout, watch: :name
  publishes :begin, at: :arbitrary_date
  publishes :conditional_event_on_save, if: -> { we_want_it }
  publishes :woof, actor: :pet, target: :self
end

class TestSubscriber < Reactor::Subscriber
  @@called = false

  on_fire do
    @@called = true
  end
end

describe Reactor::Eventable do
  before { TestSubscriber.destroy_all }
  describe 'publish' do
    let(:pet) { Pet.create! }
    let(:auction) { Auction.create!(pet: pet, arbitrary_date: DateTime.new(2012,12,21)) }

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

    it 'supports immediate events (on create) that get fired once' do
      TestSubscriber.create! event: :bell
      auction
      TestSubscriber.class_variable_get(:@@called).should be_true
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      TestSubscriber.class_variable_get(:@@called).should be_false
    end

    it 'does not publish an event scheduled for the past' do
      TestSubscriber.create! event: :begin
      auction
      TestSubscriber.class_variable_get(:@@called).should be_false
    end

    it 'does publish an event scheduled for the future' do
      TestSubscriber.create! event: :begin
      Auction.create!(pet: pet, arbitrary_date: Time.current + 1.week)
      TestSubscriber.class_variable_get(:@@called).should be_true
    end

    it 'can fire events onsave for any condition' do
      TestSubscriber.create! event: :conditional_event_on_save
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