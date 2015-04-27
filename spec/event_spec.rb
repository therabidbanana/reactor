require 'spec_helper'

module MyModule
  class Pet < ActiveRecord::Base
  end

  class Cat < Pet
  end
end

class ArbitraryModel < ActiveRecord::Base
end

class OtherWorker < ActiveJob::Base
end

describe Reactor::Event do

  let(:model) { ArbitraryModel.create! }
  let(:event_name) { :user_did_this }

  describe 'publish' do
    it 'fires the first perform and sets message event_id' do
      expect(Reactor::Event).to receive(:perform_later).with(actor_id: '1', name: event_name.to_s)
      Reactor::Event.publish(:user_did_this, actor_id: '1')
    end
  end

  describe 'perform' do
    let!(:db_subscriber) { Reactor::Subscriber.create(event_name: :user_did_this) }
    it 'fires all db subscribers' do
      Timecop.freeze do
        expect(Reactor::Jobs::SubscriberJob).to receive(:perform_later)
                                                    .with(db_subscriber,
                                                          hash_including(
                                                              name: event_name.to_s,
                                                              actor_id: model.id,
                                                              actor_type: model.class.to_s,
                                                              fired_at: Time.current.to_i))
        Reactor::Event.perform_now(name: event_name.to_s, actor_id: model.id, actor_type: model.class.to_s)
      end
    end
  end

  describe 'event content' do
    let!(:cat) { MyModule::Cat.create }
    let(:arbitrary_model) { ArbitraryModel.create }
    let(:event_data) { {random: 'data', arbitrary_model: arbitrary_model, pet: cat } }
    let(:event) { Reactor::Event.new(event_data) }

    describe 'data key fallthrough' do
      subject { event }

      describe 'getters' do
        context 'basic key value' do
          its(:random) { is_expected.to eq('data') }
        end

        context 'foreign key and foreign type' do
          its(:pet) { is_expected.to be_a MyModule::Cat }
          its('pet.id') { is_expected.to eq(MyModule::Cat.last.id) }
        end
      end

      describe 'setters' do
        it 'sets simple keys' do
          event.simple = 'key'
          expect(event.data[:simple]).to eq('key')
        end

        it 'sets active_record polymorphic keys' do
          event.complex = cat = MyModule::Cat.create
          expect(event.complex_id).to eql(cat.id)
          expect(event.complex_type).to eql(cat.class.to_s)
        end
      end
    end

    describe 'data' do
      let(:serialized_event) { event.data }
      specify { expect(serialized_event).to be_a Hash }
      specify { expect(serialized_event[:random]).to eq('data') }
    end

    describe 'new' do
      specify { expect(event).to be_a Reactor::Event }
      specify { expect(event.arbitrary_model).to eq(arbitrary_model) }
      specify { expect(event.random).to eq('data') }
    end
  end
end
