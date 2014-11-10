require 'spec_helper'

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
      expect(Reactor::Event).to receive(:publish).with(:an_event, what: 'the', actor: auction)
      auction.publish(:an_event, {what: 'the'})
    end

    it 'publishes an event with provided actor and target methods' do
      allow(Reactor::Event).to receive(:publish).exactly(5).times
      auction
      expect(Reactor::Event).to have_received(:publish).with(:woof, a_hash_including(actor: pet, target: auction))
    end

    it 'reschedules an event when the :at time changes' do
      start_at = auction.start_at
      new_start_at = start_at + 1.week
      expect(Reactor::Event).to receive(:reschedule).with :ring, anything
      expect(Reactor::Event).to receive(:reschedule).with(:begin,
        a_hash_including(
          at: new_start_at,
          actor: auction,
          was: start_at,
          additional_info: 'curtis was here'
        )
      )
      auction.start_at = new_start_at
      auction.save!
    end

    it 'reschedules an event when the :watch field changes' do
      ring_time = auction.ring_timeout
      new_start_at = auction.start_at + 1.week
      new_ring_time = new_start_at + 30.seconds
      expect(Reactor::Event).to receive(:reschedule).with :begin, anything
      expect(Reactor::Event).to receive(:reschedule).with(:ring,
        a_hash_including(
          at: new_ring_time,
          actor: auction,
          was: ring_time
        )
      )
      auction.start_at = new_start_at
      auction.save!
    end

    it 'supports immediate events (on create) that get fired once' do
      TestSubscriber.create! event_name: :bell
      auction
      expect(TestSubscriber.class_variable_get(:@@called)).to be_truthy
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      expect(TestSubscriber.class_variable_get(:@@called)).to be_falsey
    end

    it 'does not publish an event scheduled for the past' do
      TestSubscriber.create! event_name: :begin
      auction
      expect(TestSubscriber.class_variable_get(:@@called)).to be_falsey
    end

    it 'does publish an event scheduled for the future' do
      TestSubscriber.create! event_name: :begin
      Auction.create!(pet: pet, start_at: Time.current + 1.week)

      expect(TestSubscriber.class_variable_get(:@@called)).to be_truthy
    end

    it 'can fire events onsave for any condition' do
      TestSubscriber.create! event_name: :conditional_event_on_save
      auction
      TestSubscriber.class_variable_set(:@@called, false)
      auction.start_at = 1.day.from_now
      auction.save
      expect(TestSubscriber.class_variable_get(:@@called)).to be_falsey
      auction.start_at = 2.days.from_now
      auction.we_want_it = true
      auction.save
      expect(TestSubscriber.class_variable_get(:@@called)).to be_truthy
    end
  end
end
