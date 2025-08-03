require 'spec_helper'

RSpec.describe Railbox::Processors::HttpProcessor do
  describe '.process' do
    let(:record) do
      double(
        'TransactionalOutbox',
        action_data: {
          method_name: :post,
          url:         'https://example.com/api'
        },
        query:       {q: 1},
        body:        {data: 'test'},
        headers:     {'Custom-Header' => '123'}
      )
    end

    it 'calls Railbox::HttpClient::Faraday.request with correct arguments' do
      allow(Railbox::HttpClient::Faraday).to receive(:request)
      described_class.process(record)
      expect(Railbox::HttpClient::Faraday).to have_received(:request).with(
        :post,
        'https://example.com/api',
        {q: 1},
        {data: 'test'},
        {'Custom-Header' => '123'}
      )
    end

    it 'raises error when Railbox::HttpClient::Faraday.request raises an exception' do
      allow(Railbox::HttpClient::Faraday).to receive(:request).and_raise(StandardError, 'fail')
      expect {
        described_class.process(record)
      }.to raise_error(StandardError, 'fail')
    end
  end
end
