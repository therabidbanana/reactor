require 'spec_helper'

describe Reactor do
  subject { Reactor }

  describe '.test_mode!' do
    it 'sets Reactor into test mode' do
      Reactor.test_mode?.should be_false
      Reactor.test_mode!
      Reactor.test_mode?.should be_true
    end
  end
end
