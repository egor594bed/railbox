module Railbox
  module Queue
    # HandlingQueue is responsible for enqueuing "class method call" actions into the transactional outbox table.
    #
    # Usage example:
    #   Railbox::HandlingQueue.enqueue(
    #     service: "MyService",
    #     method: "perform_action",
    #     body: { key: "value" },
    #     headers: { ... },
    #     query: { ... },
    #     entity_type: "User",
    #     entity_id: 123,
    #     meta: { ... }
    #   )
    #
    # This method creates a Railbox::TransactionalOutboxMutator record to be processed by a background job later,
    # enabling reliable, auditable, and decoupled invocation of class methods in your system.
    #
    # A ValidationError is raised if the given options are invalid (for example, missing class, method, or incorrect body format).
    #
    class HandlingQueue < BaseQueue
      OPTIONS = %i[headers query entity_type entity_id meta].freeze

      class << self
        # Enqueues a class method call operation for asynchronous processing via the transactional outbox.
        #
        # @param service [String] Name of the target service class (must exist).
        # @param method [String, Symbol] Name of the public class method to call (default: 'create').
        # @param body [Hash] The request payload (must be a Hash)
        # @param opts [Hash] Optional parameters: headers, query, entity_type, entity_id, meta.
        # @raise [ValidationError] If the service, method, or body are invalid.
        # @return [Boolean] true if enqueuing succeeds.
        #
        def enqueue(service:, method: 'create', body: {}, **opts)
          opts.deep_symbolize_keys!.slice!(*OPTIONS)
          validate_options(service, method, body, **opts)

          to_queue(
            action_type: 'handler',
            action_data: {class_name: service, method_name: method},
            body:        body,
            status:      'in_progress',
            **opts
          )

          true
        end

        private

        def validate_options(service, method, body, **opts)
          raise ValidationError, "Service #{service} is not present" unless service.present?
          raise ValidationError, "Service class #{service} is not defined" unless Object.const_defined?(service)
          raise ValidationError, "Method #{method} for class #{service} is not defined" unless Object.const_get(service).respond_to?(method)
          raise ValidationError, 'Body must be a Hash' unless body.is_a?(Hash)

          raise ValidationError, "Model #{opts[:entity_type]} is not defined" unless Object.const_defined?(opts[:entity_type]) if opts[:entity_type].present?
        end
      end
    end
  end
end
