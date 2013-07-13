require 'spec_helper'


class Auction < ActiveRecord::Base
  on_event :bid_made do |event|
    event.target.update_column :status, 'first_bid_made'
  end
end

describe Reactor::Subscribable do

  describe 'subscribes_to' do
    it 'binds block of code statically to event being fired' do
      Auction.any_instance.should_receive(:update_column).with(:status, 'first_bid_made')
      Reactor::Event.publish(:bid_made, target: Auction.create)
    end
  end
end