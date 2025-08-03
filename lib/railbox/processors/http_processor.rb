module Railbox
  module Processors
    class HttpProcessor
      class << self

        def process(record)
          action_data = record.action_data.deep_symbolize_keys!

          Railbox::HttpClient::Faraday.request(action_data[:method_name],
                                               action_data[:url],
                                               record.query,
                                               record.body,
                                               record.headers)
        end
      end
    end
  end
end
