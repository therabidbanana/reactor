require 'spec_helper'

class RandomActionController

  def self.around_filter(method)
    @around_filter ||= method
  end

  include Reactor::ResourceActionable
  actionable_resource :@cat
  nested_resource :@owner

  attr_accessor :action_name
  def initialize
    self.action_name = 'create'
  end

  def create
    #because I dont feel like re-implementing around_filter for this stub
    infer_basic_action_event do
      @owner = ArbitraryModel.create!
      @cat = Pet.create!
    end
  end

end

describe Reactor::ResourceActionable do
  let(:controller_stub) { RandomActionController.new }

  describe "when action strategy class exists" do
    it 'runs the strategy of the matching name' do
      expect(Reactor::ResourceActionable::CreateEvent).to receive(:perform_on).with(controller_stub)
      controller_stub.create
    end
  end

  describe "when action is non-standard rails CRUD action" do
    it 'fires a basic action_event' do
      controller_stub.action_name = 'do_thing'
      expect(controller_stub).to receive(:action_event).with("cat_do_thing")
      controller_stub.create
    end
  end
end

describe "ActionEvents" do
  let(:actionable_resource) { ArbitraryModel.create! }
  let(:nested_resource) { Pet.create! }
  let(:ctrl_stub) { double(resource_name: "cat", actionable_resource: actionable_resource, nested_resource: nested_resource, params: {'cat' => {name: "Sasha"}} ) }

  describe "ShowEvent" do
    after { Reactor::ResourceActionable::ShowEvent.perform_on(ctrl_stub) }
    specify { expect(ctrl_stub).to receive(:action_event).with("cat_viewed", target: actionable_resource) }
  end

  describe "EditEvent" do
    after { Reactor::ResourceActionable::EditEvent.perform_on(ctrl_stub) }
    specify { expect(ctrl_stub).to receive(:action_event).with("edit_cat_form_viewed", target: actionable_resource) }
  end

  describe "NewEvent" do
    after { Reactor::ResourceActionable::NewEvent.perform_on(ctrl_stub) }
    specify { expect(ctrl_stub).to receive(:action_event).with("new_cat_form_viewed", target: nested_resource) }
  end

  describe "IndexEvent" do
    after { Reactor::ResourceActionable::IndexEvent.perform_on(ctrl_stub) }
    specify { expect(ctrl_stub).to receive(:action_event).with("cats_indexed", target: nested_resource) }
  end

  describe "DestroyEvent" do
    after { Reactor::ResourceActionable::DestroyEvent.perform_on(ctrl_stub) }
    specify { expect(ctrl_stub).to receive(:action_event).with("cat_destroyed", last_snapshot: actionable_resource.as_json) }
  end

  describe "CreateEvent" do
    after { Reactor::ResourceActionable::CreateEvent.perform_on(ctrl_stub) }

    describe "when resource is valid" do
      before { expect(actionable_resource).to receive(:valid?).and_return(true) }

      specify do
        expect(ctrl_stub).to receive(:action_event)
          .with("cat_created",
                target: actionable_resource,
                attributes: {name: "Sasha"})
      end
    end

    describe "when resource is not valid" do
      before do
        expect(actionable_resource).to receive(:valid?).and_return(false)
        expect(actionable_resource).to receive(:errors).and_return('awesomeness' => 'too awesome')
      end

      specify do
        expect(ctrl_stub).to receive(:action_event)
          .with("cat_create_failed",
                errors: {'awesomeness' => 'too awesome'},
                target: nested_resource,
                attributes: {name: "Sasha"})
      end
    end
  end

  describe "UpdateEvent" do
    after { Reactor::ResourceActionable::UpdateEvent.perform_on(ctrl_stub) }

    describe "when resource is valid" do
      before do
        expect(actionable_resource).to receive(:valid?).and_return(true)
        expect(actionable_resource).to receive(:previous_changes).and_return({'name' => [nil, "Sasha"]})
      end

      specify do
        expect(ctrl_stub).to receive(:action_event)
          .with("cat_updated",
                target: actionable_resource,
                changes: {'name' => [nil, "Sasha"]})
      end
    end

    describe "when resource is not valid" do
      before do
        expect(actionable_resource).to receive(:valid?).and_return(false)
        expect(actionable_resource).to receive(:errors).and_return('awesomeness' => 'too awesome')
      end

      specify do
        expect(ctrl_stub).to receive(:action_event)
          .with("cat_update_failed",
              target: actionable_resource,
              errors: {'awesomeness' => 'too awesome'},
              attributes: {name: "Sasha"})
      end
    end
  end

end