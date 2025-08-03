require 'spec_helper'

RSpec.describe Railbox::HandlingQueue do
  describe '.enqueue' do
    let(:service_class) do
      # Temporary dummy class for enqueue test
      Class.new do
        def self.create(*)
        end

        def self.perform_action(*)
        end
      end
    end
    let(:service_name) { 'DummyService' }
    let(:valid_body)   { {foo: 'bar'} }

    before do
      stub_const(service_name, service_class)
    end

    it 'creates a Railbox::TransactionalOutbox with correct attributes' do
      expect {
        described_class.enqueue(service: service_name, method: :perform_action, body: valid_body)
      }.to change { Railbox::TransactionalOutbox.count }.by(1)

      record = Railbox::TransactionalOutbox.last
      expect(record.action_type).to eq('handler')
      expect(record.action_data).to eq({'class_name' => service_name, 'method_name' => 'perform_action'})
      expect(record.body).to eq(valid_body.stringify_keys)
    end

    it 'uses "create" as the default method' do
      expect {
        described_class.enqueue(service: service_name, body: valid_body)
      }.to change { Railbox::TransactionalOutbox.count }.by(1)

      record = Railbox::TransactionalOutbox.last
      expect(record.action_data).to eq({'class_name' => service_name, 'method_name' => 'create'})
    end

    it 'raises ValidationError if service name is blank' do
      expect {
        described_class.enqueue(service: '', method: :create, body: valid_body)
      }.to raise_error(Railbox::ValidationError, /is not present/)
    end

    it 'raises ValidationError if service class is not defined' do
      expect {
        described_class.enqueue(service: 'NotExistentClass', method: :create, body: valid_body)
      }.to raise_error(Railbox::ValidationError, /is not defined/)
    end

    it 'raises ValidationError if method is not implemented' do
      expect {
        described_class.enqueue(service: service_name, method: :not_existing, body: valid_body)
      }.to raise_error(Railbox::ValidationError, /is not defined/)
    end

    it 'raises ValidationError if body is not a Hash' do
      expect {
        described_class.enqueue(service: service_name, body: 'string')
      }.to raise_error(Railbox::ValidationError, /Body must be a Hash/)
    end

    it 'accepts all supported options' do
      expect {
        described_class.enqueue(
          service: service_name,
          body:    valid_body,
          headers: {'foo' => 'bar'},
          query:   {q: 1},
          meta:    {task: '42'}
        )
      }.to change { Railbox::TransactionalOutbox.count }.by(1)

      record = Railbox::TransactionalOutbox.last
      expect(record.headers).to eq({'foo' => 'bar'})
      expect(record.query).to eq({'q' => 1})
      expect(record.meta).to eq({'task' => '42'})
    end
  end
end