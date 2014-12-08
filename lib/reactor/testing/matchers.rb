RSpec::Matchers.define :publish_event do |name, data = {}|
  supports_block_expectations

  match do |block|
    defaults = {:actor => anything}

    allow(Reactor::Event).to receive(:publish)

    block.call

    expect(Reactor::Event).to have_received(:publish).with(name, a_hash_including(defaults.merge(data))).at_least(:once)
  end
end

RSpec::Matchers.define :publish_events do |*names|
  supports_block_expectations

  match do |block|
    defaults = {:actor => anything}

    allow(Reactor::Event).to receive(:publish)

    block.call

    names.each do |name|
      expect(Reactor::Event).to have_received(:publish).with(name, a_hash_including(defaults)).at_least(:once)
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
