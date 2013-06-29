RSpec::Matchers.define :publish_event do |name, data = {}|

  match do |block|
    if data.empty?
      Reactor::Event.should_receive(:publish).with do |*args|
        args.first.should == name
      end
    else
      Reactor::Event.should_receive(:publish).with(name, data)
    end
    block.call
  end
end