module Railbox
  module HttpClient
    class Faraday
      class << self
        def request(method, url, query = {}, body = {}, headers = {})
          connection = ::Faraday.new do |config|
            config.adapter :httpclient
            config.request :json
            config.response :json, parser_options: {symbol_keys: true}
            config.response :raise_error

            config.response :logger, Rails.logger, logger_options
          end

          connection.send(method, url) do |req|
            req.params  = query if query.present?
            req.headers = headers if headers.present?
            req.body    = body if body.present? && method != :get
          end
        end

        def logger_options
          {
            headers:   {request: true, response: true},
            bodies:    {request: true, response: true},
            errors:    true,
            log_level: :info
          }
        end
      end
    end
  end
end
