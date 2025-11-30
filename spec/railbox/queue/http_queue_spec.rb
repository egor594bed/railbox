require 'spec_helper'

RSpec.describe Railbox::HttpQueue do
  describe '.enqueue' do
    let(:valid_url)    { 'https://example.com/path' }
    let(:valid_method) { :post }
    let(:valid_body)   { {foo: 'bar'} }
    let(:valid_headers){ {'X-Token' => 'abc'} }

    it 'creates a Railbox::TransactionalOutbox with correct attributes' do
      expect do
        described_class.enqueue(url: valid_url, method: valid_method, body: valid_body, headers: valid_headers)
      end.to change { Railbox::TransactionalOutbox.count }.by(1)

      record = Railbox::TransactionalOutbox.last
      expect(record.action_type).to eq('http_request')
      expect(record.action_data).to eq({url: valid_url, method_name: valid_method.to_s})
      expect(record.body).to eq(valid_body.stringify_keys)
      expect(record.headers).to eq(valid_headers.stringify_keys)
    end

    it 'raises ValidationError for invalid url' do
      expect do
        described_class.enqueue(url: 'ftp://wrong.com', method: valid_method, body: valid_body)
      end.to raise_error(Railbox::ValidationError, /Url .* is not valid/)
    end

    it 'raises ValidationError for wrong method' do
      expect do
        described_class.enqueue(url: valid_url, method: :foo, body: valid_body)
      end.to raise_error(Railbox::ValidationError, /Invalid method: foo/)
    end

    it 'raises ValidationError for body which is not a Hash' do
      expect do
        described_class.enqueue(url: valid_url, body: 'not a hash')
      end.to raise_error(Railbox::ValidationError, /Body must be a Hash/)
    end

    it 'accepts query and meta options' do
      expect do
        described_class.enqueue(url: valid_url, query: {p: 1}, meta: {x:'y'})
      end.to change { Railbox::TransactionalOutbox.count }.by(1)

      record = Railbox::TransactionalOutbox.last
      expect(record.query).to eq({'p' => 1})
      expect(record.meta).to eq({'x' => 'y'})
    end
  end
end
