# Module to be included in service classes for adding queue processing support
# and an additional `outbox_entity` property.
#
# @example Usage
#   class MyService
#     include Railbox::Handler
#   end
#
#   MyService.enqueue(method: 'update', body: { key: 'value' })
#
# @!method outbox_entity
#   @return [Object] Returns the current value of outbox_entity.
#
module Railbox
  module Handler
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :outbox_entity

      # Queues a request for asynchronous execution
      # @param method [String] to be called (default: 'create')
      # @param body [Hash] main payload for the handler
      # @param opts [Hash] any additional options (e.g. relative_entity/meta)
      #
      def enqueue(method: 'create', body: {}, **opts)
        HandlingQueue.enqueue(service: name, method: method, body: body, **opts)
      end
    end
  end
end
