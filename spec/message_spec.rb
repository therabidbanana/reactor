require 'spec_helper'
require 'support/active_record'

module MyModule
  class Pet < ActiveRecord::Base
  end

  class Cat < Pet
  end
end


class ArbitraryModel < ActiveRecord::Base
end

describe Reactor::Message do
  let(:cat) { MyModule::Cat.create }
  let(:arbitrary_model) { ArbitraryModel.create }
  let(:message_data) { {random: 'data', pet_id: cat.id, pet_type: cat.class.to_s, arbitrary_model: arbitrary_model } }
  let(:message) { Reactor::Message.new(message_data) }

  describe 'data key fallthrough' do
    subject { message }

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
        message.simple = 'key'
        message.data[:simple].should == 'key'
      end

      it 'sets active_record polymorphic keys' do
        message.complex = cat = MyModule::Cat.create
        message.complex_id = cat.id
        message.complex_type = cat.class.to_s
      end
    end
  end

  describe 'data' do
    let(:serialized_message) { message.data }
    specify { serialized_message.should be_a Hash }
    specify { serialized_message[:random].should == 'data' }
  end

  describe 'new' do
    specify { message.should be_a Reactor::Message }
    specify { message.pet_id.should == cat.id }
    specify { message.arbitrary_model_id.should == arbitrary_model.id }
  end
end
