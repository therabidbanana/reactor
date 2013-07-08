RSpec::Matchers.define :publish_event do |name, data = {}|

  match do |block|
    defaults = {:actor => anything, :target => anything}
    Reactor::Event.should_receive(:publish).with(name, defaults.merge(data))
    block.call
  end
end

RSpec::Matchers.define :publish_events do |*args|

  match do |block|
    defaults = {:actor => anything, :target => anything}

    args.each do |event|
      case event
        when Symbol
          Reactor::Event.should_receive(:publish).with(event, anything)
        when Hash
          Reactor::Event.should_receive(:publish).with(event.keys.first, defaults.merge(event.values.first))
      end
    end
    block.call
  end
end