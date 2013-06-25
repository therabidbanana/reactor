require 'spec_helper'

class Auction < ActiveRecord::Base
  def ring_timeout(was: false)
    created_at + (was ? 10.seconds : 30.seconds)
  end

  publishes :ring, at: :ring_timeout, watch: :name
end

describe Reactor::Eventable do
  describe 'publish' do
    let(:auction) { Auction.create }
    it 'publishes an event with actor_id and actor_type set as self' do
      Reactor::Event.should_receive(:publish).with(:an_event, {what: 'the', actor_id: auction.id, actor_type: auction.class.to_s}).twice
      auction.publish(:an_event, {what: 'the'})
    end
  end
end