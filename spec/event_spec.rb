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

  let(:model) { ArbitraryModel.create! }
  let(:event_name) { :user_did_this }

  describe 'publish' do
    it 'fires the first perform and sets message event_id' do
      expect(Reactor::Event).to receive(:perform_async).with(event_name, 'actor_id' => '1', 'event' => :user_did_this)
      Reactor::Event.publish(:user_did_this, actor_id: '1')
    end
  end

  describe 'perform' do
    before { Reactor::Subscriber.create(event_name: :user_did_this) }
    after { Reactor::Subscriber.destroy_all }
    it 'fires all subscribers' do
      expect_any_instance_of(Reactor::Subscriber).to receive(:fire).with(hash_including(actor_id: model.id.to_s))
      Reactor::Event.perform(event_name, actor_id: model.id.to_s, actor_type: model.class.to_s)
    end

    it 'sets a fired_at key in event data' do
      expect_any_instance_of(Reactor::Subscriber).to receive(:fire).with(hash_including(fired_at: anything))
      Reactor::Event.perform(event_name, actor_id: model.id.to_s, actor_type: model.class.to_s)
    end

    it 'works with the legacy .process method, too' do
      expect_any_instance_of(Reactor::Subscriber).to receive(:fire).with(hash_including(actor_id: model.id.to_s))
      Reactor::Event.perform(event_name, actor_id: model.id.to_s, actor_type: model.class.to_s)
    end

    describe 'when subscriber throws exception', :sidekiq do
      let(:mock) { double(:thing, some_method: 3) }
      let(:barfing_event) { Reactor::Event.perform('barfed', somethin: 'up', actor_id: model.id.to_s, actor_type: model.class.to_s) }

      before do
        Reactor::SUBSCRIBERS['barfed'] ||= []
        Reactor::SUBSCRIBERS['barfed'] << Reactor::Subscribable::StaticSubscriberFactory.create('barfed') do |event|
          raise 'UNEXPECTED!'
        end
        Reactor::SUBSCRIBERS['barfed'] << Reactor::Subscribable::StaticSubscriberFactory.create('barfed') do |event|
          mock.some_method
        end
      end

      it 'doesnt matter because it runs in a separate worker process' do
        expect { barfing_event }.to_not raise_exception
      end
    end
  end

  describe 'reschedule', :sidekiq do
    let(:scheduled) { Sidekiq::ScheduledSet.new }
    let(:time) { 1.hour.from_now }

    before do
      Sidekiq::Worker.clear_all
    end

    it 'can schedule and reschedule an event in the future' do
      expect {
        jid = Reactor::Event.publish :turtle_time, at: time
        expect(scheduled.find_job(jid).score).to eq(time.to_f)
      }.to change { scheduled.size }.by(1)

      expect {
        jid = Reactor::Event.reschedule :turtle_time, at: (time + 2.hours), was: time
        expect(scheduled.find_job(jid).score).to eq((time + 2.hours).to_f)
      }.to_not change { scheduled.size }
    end

    it 'will schedule an event in the future even if that event was not previously scheduled in the past' do
      expect {
        jid = Reactor::Event.reschedule :no_old_turtule_time, at: (time + 2.hours), was: time
        expect(scheduled.find_job(jid).score).to eq((time + 2.hours).to_f)
      }.to change{ scheduled.size }.by(1)
    end

    it 'will not schedule an event when the time passed in is nil' do
      expect {
        Reactor::Event.reschedule :no_old_turtule_time, at: nil, was: time
      }.to_not change{ scheduled.size }
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
          event.complex_id = cat.id
          event.complex_type = cat.class.to_s
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
      specify { expect(event.pet_id).to eq(cat.id) }
      specify { expect(event.arbitrary_model_id).to eq(arbitrary_model.id) }
    end
  end
end
