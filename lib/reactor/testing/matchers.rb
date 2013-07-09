RSpec::Matchers.define :publish_event do |name, data = {}|

  match do |block|
    defaults = {:actor => anything}
    Reactor::Event.should_receive(:publish).with(name, hash_including(defaults.merge(data)))
    block.call
  end
end

RSpec::Matchers.define :publish_events do |*events|

  match do |block|
    defaults = {:actor => anything, at: anything, target: anything}

    Reactor::Event.should_receive(:publish).exactly(events.count).times.with do |event, data|
      match = events.select { |e| (e.is_a?(Hash) ? e.keys.first : e) == event }.first
      match.should be_present

      expected = match.is_a?(Hash) ? match.values.first : {match => {}}
      expected.each do |key, value|
        value.should == expected[key]
      end
    end
    block.call
  end
end