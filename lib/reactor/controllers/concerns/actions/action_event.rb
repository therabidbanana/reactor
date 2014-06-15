class Reactor::ResourceActionable::ActionEvent
  def self.perform(&block)
    @perform_block = block
  end

  def self.perform_on(ctx)
    ctx.instance_exec(&@perform_block)
  end
end