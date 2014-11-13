RSpec::Matchers.define :publish_event do |name, data = {}|
  supports_block_expectations

  match do |block|
    defaults = {:actor => anything}

    allow(Reactor::Event).to receive(:publish).with(name, a_hash_including(defaults.merge(data)))

    block.call

    expect(Reactor::Event).to have_received(:publish).with(name, a_hash_including(defaults.merge(data)))
  end
end

RSpec::Matchers.define :publish_events do |*names|
  supports_block_expectations

  match do |block|
    defaults = {:actor => anything}

    names.each do |name|
      allow(Reactor::Event).to receive(:publish).with(name, a_hash_including(defaults))
    end

    block.call

    names.each do |name|
      expect(Reactor::Event).to have_received(:publish).with(name, a_hash_including(defaults))
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
