RSpec::Matchers.define :publish_event do |name, data = {}|
  supports_block_expectations

  match do |block|
    defaults = {:actor => anything}
    expect(Reactor::Event).to receive(:publish).with(name, hash_including(defaults.merge(data)))

    begin
      block.call
      RSpec::Mocks::verify
      true
    rescue RSpec::Mocks::MockExpectationError => e
      false
    end
  end
end

RSpec::Matchers.define :publish_events do |*events|
  supports_block_expectations

  match do |block|
    expect(Reactor::Event).to receive(:publish).exactly(events.count).times do |event, data|
      match = events.select { |e| (e.is_a?(Hash) ? e.keys.first : e) == event }.first
      expect(match).to be_present

      expected = match.is_a?(Hash) ? match.values.first : {match => {}}
      expected.each do |key, value|
        expect(value).to eq(expected[key])
      end
    end

    begin
      block.call
      RSpec::Mocks::verify
      true
    rescue RSpec::Mocks::MockExpectationError => e
      false
    end
  end
end

RSpec::Matchers.define :subscribe_to do |name, data = {}, &expectations|
  supports_block_expectations

  match do
    expectations.call if expectations.present?
    Reactor::Event.publish(name, data)
  end
end
