module Railbox
  module Queue
    # HttpQueue is responsible for enqueuing HTTP request actions into the transactional outbox.
    #
    # Usage example:
    #   Railbox::HttpQueue.enqueue(
    #     url: "https://example.com/api",
    #     method: :post,
    #     body: { data: 1 },
    #     headers: { "Authorization" => "Bearer ..." },
    #     query: { foo: "bar" },
    #     meta: { correlation_id: "123" }
    #   )
    #
    # This creates a Railbox::TransactionalOutboxMutator record, which will be processed later by a background worker,
    # providing reliable, traceable, and decoupled execution of HTTP requests.
    #
    # A ValidationError will be raised if the url, method, or body are invalid.
    #
    class HttpQueue < BaseQueue
      OPTIONS = %i[query meta group].freeze
      METHODS = %i[get post put patch delete].freeze

      class << self
        # Enqueues an HTTP request action for asynchronous processing via the transactional outbox.
        #
        # @param url [String] The HTTP endpoint URL (must begin with http:// or https://).
        # @param method [Symbol] HTTP method to use (:get, :post, :put, :patch, :delete). Defaults to :post.
        # @param body [Hash] Request payload (must be a Hash). Defaults to empty hash.
        # @param headers [Hash] Optional HTTP headers.
        # @param opts [Hash] Additional options: query, meta, group.
        # @raise [ValidationError] If the url, method, or body are invalid.
        # @return [Boolean] true if enqueuing is successful.
        #
        def enqueue(url:, method: :post, body: {}, headers: {}, **opts)
          opts.deep_symbolize_keys!.slice!(*OPTIONS)
          validate_options(url, method, body)

          to_queue(
            action_type: 'http_request',
            action_data: {url: url, method_name: method},
            body:        body,
            headers:     headers,
            status:      'in_progress',
            **opts
          )

          true
        end

        private

        def validate_options(url, method, body)
          raise ValidationError, "Url #{url} is not valid" unless %r{\Ahttps?://[^\s/$.?#].\S*\z}i.match?(url)
          raise ValidationError, "Invalid method: #{method}. Allowed methods are: #{METHODS.join(', ')}" unless METHODS.include?(method)
          raise ValidationError, 'Body must be a Hash' unless body.is_a?(Hash)
        end
      end
    end
  end
end
