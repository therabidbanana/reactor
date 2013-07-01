require 'spec_helper'

module MyModule
  class Pet < ActiveRecord::Base
  end

  class Cat < Pet
  end
end

class ArbitraryModel < ActiveRecord::Base
end


describe Reactor::Event do

  let(:event_name) { :user_did_this }

  describe 'publish' do
    it 'fires the first process and sets message event_id' do
      Reactor::Event.should_receive(:process).with(event_name, 'actor_id' => '1', 'event' => :user_did_this)
      Reactor::Event.publish(:user_did_this, actor_id: '1')
    end
  end

  describe 'process' do
    it 'fires all subscribers' do
      Reactor::Subscriber.create(event: :user_did_this)
      Reactor::Subscriber.any_instance.should_receive(:fire).with(actor_id: '1')
      Reactor::Event.process(event_name, actor_id: '1')
    end
  end

  describe 'event content' do
    let(:cat) { MyModule::Cat.create }
    let(:arbitrary_model) { ArbitraryModel.create }
    let(:event_data) { {random: 'data', pet_id: cat.id, pet_type: cat.class.to_s, arbitrary_model: arbitrary_model } }
    let(:event) { Reactor::Event.new(event_data) }

    describe 'data key fallthrough' do
      subject { event }

      describe 'getters' do
        context 'basic key value' do
          its(:random) { should == 'data' }
        end

        context 'foreign key and foreign type' do
          its(:pet) { should be_a MyModule::Cat }
          its('pet.id') { should == MyModule::Cat.last.id }
        end
      end

      describe 'setters' do
        it 'sets simple keys' do
          event.simple = 'key'
          event.data[:simple].should == 'key'
        end

        it 'sets active_record polymorphic keys' do
          event.complex = cat = MyModule::Cat.create
          event.complex_id = cat.id
          event.complex_type = cat.class.to_s
        end
      end
    end

    describe 'data' do
      let(:serialized_event) { event.data }
      specify { serialized_event.should be_a Hash }
      specify { serialized_event[:random].should == 'data' }
    end

    describe 'new' do
      specify { event.should be_a Reactor::Event }
      specify { event.pet_id.should == cat.id }
      specify { event.arbitrary_model_id.should == arbitrary_model.id }
    end
  end
end
