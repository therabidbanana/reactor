require 'spec_helper'


class Auction < ActiveRecord::Base
  on_event :bid_made do |event|
    event.target.update_column :status, 'first_bid_made'
  end

  on_event :puppy_delivered, :ring_bell
  on_event :any_event, -> (event) {  puppies! }
  on_event :pooped, :pick_up_poop, delay: 5.minutes
  on_event '*' do |event|
    event.actor.more_puppies! if event.name == 'another_event'
  end

  def self.ring_bell(event)
    pp "ring ring! #{event}"
  end
end

describe Reactor::Subscribable do
  let(:scheduled) { Sidekiq::ScheduledSet.new }

  describe 'on_event' do
    it 'binds block of code statically to event being fired' do
      Auction.any_instance.should_receive(:update_column).with(:status, 'first_bid_made')
      Reactor::Event.publish(:bid_made, target: Auction.create)
    end

    describe 'binding symbol of class method' do
      it 'fires on event' do
        Auction.should_receive(:ring_bell)
        Reactor::Event.publish(:puppy_delivered)
      end

      it 'can be delayed' do
        Auction.should_receive(:pick_up_poop)
        Auction.should_receive(:delay_for).with(5.minutes).and_return(Auction)
        Reactor::Event.perform('pooped', {})
      end
    end

    it 'binds proc' do
      Auction.should_receive(:puppies!)
      Reactor::Event.publish(:any_event)
    end

    it 'accepts wildcard event name' do
      Auction.any_instance.should_receive(:more_puppies!)
      Reactor::Event.publish(:another_event, actor: Auction.create)
    end
  end
end
