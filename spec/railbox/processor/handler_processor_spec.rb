require 'spec_helper'

RSpec.describe Railbox::Processors::HandlerProcessor do
  describe '.process' do
    let(:record) do
      double(
        'TransactionalOutbox',
        action_data: {class_name: 'TestHandler', method_name: :execute}
      )
    end

    let(:interface_instance) { instance_double('Railbox::TransactionalOutboxInterface') }

    before do
      stub_const('TestHandler', Class.new do
        class << self
          attr_accessor :outbox_entity, :called

          def execute
            @called = outbox_entity
          end
        end
      end)

      allow(Railbox::TransactionalOutboxInterface).to receive(:new)
        .with(record)
        .and_return(interface_instance)
    end

    it 'sets entity, calls target method and resets entity' do
      described_class.process(record)
      expect(TestHandler.called).to eq(interface_instance)
      expect(TestHandler.outbox_entity).to be_nil
    end

    it 'calls only the method specified in action_data[:method]' do
      TestHandler.define_singleton_method(:other_method) {}
      record_with_other = double(
        'TransactionalOutbox',
        action_data: { class_name: 'TestHandler', method_name: :other_method }
      )
      allow(Railbox::TransactionalOutboxInterface).to receive(:new)
        .with(record_with_other)
        .and_return(interface_instance)
      expect(TestHandler).to receive(:other_method)
      described_class.process(record_with_other)
    end

    it 'raises NameError if handler class is not defined' do
      bad_record = double(
        'TransactionalOutbox',
        action_data: {class_name: 'NoSuchHandler', method_name: :foo}
      )
      allow(Railbox::TransactionalOutboxInterface).to receive(:new)
        .with(bad_record)
        .and_return(interface_instance)
      expect {
        described_class.process(bad_record)
      }.to raise_error(NameError)
    end

    it 'raises NoMethodError if handler method is not defined' do
      record_bad_method = double(
        'TransactionalOutbox',
        action_data: {class_name: 'TestHandler', method_name: :not_exist}
      )
      allow(Railbox::TransactionalOutboxInterface).to receive(:new)
        .with(record_bad_method)
        .and_return(interface_instance)
      expect {
        described_class.process(record_bad_method)
      }.to raise_error(NoMethodError)
    end
  end
end
