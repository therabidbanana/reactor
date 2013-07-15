require 'spec_helper'


class Auction < ActiveRecord::Base
  on_event :bid_made do |event|
    event.target.update_column :status, 'first_bid_made'
  end

  on_event :puppy_delivered, :ring_bell
  on_event :any_event, -> (event) {  puppies! }

  def self.ring_bell(event)
    pp "ring ring! #{event}"
  end
end

describe Reactor::Subscribable do

  describe 'on_event' do
    it 'binds block of code statically to event being fired' do
      Auction.any_instance.should_receive(:update_column).with(:status, 'first_bid_made')
      Reactor::Event.publish(:bid_made, target: Auction.create)
    end

    it 'binds symbol to class method' do
      Auction.should_receive(:ring_bell)
      Reactor::Event.publish(:puppy_delivered)
    end

    it 'binds proc' do
      Auction.should_receive(:puppies!)
      Reactor::Event.publish(:any_event)
    end
  end
end