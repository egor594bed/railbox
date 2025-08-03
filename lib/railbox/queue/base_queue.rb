module Railbox
  module Queue
    # Abstract base class for enqueuing tasks into the transactional outbox.
    #
    # This class is intended to be subclassed: descendants should implement their own logic for enqueuing tasks.
    #
    # Usage example:
    #   class MyQueue < Railbox::BaseQueue
    #     def self.enqueue(**opts)
    #       # your implementation here
    #     end
    #   end
    #
    # The .enqueue method **must** be implemented in each subclass.
    # Calling .enqueue directly on BaseQueue will raise NotImplementedError.
    #
    class BaseQueue
      class << self
        # Abstract method for enqueuing a task into the outbox.
        #
        # Each subclass must override this method with specific logic.
        #
        # @param opts [Hash] Parameters required by a particular implementation.
        # @raise [NotImplementedError] if the method is not overridden in a subclass.
        #
        def enqueue(**_)
          raise NotImplementedError, 'You must implement this method'
        end

        private

        # Creates a record in the transactional outbox with the given attributes.
        #
        # @param attributes [Hash] Record attributes
        # @return [Railbox::TransactionalOutboxMutator] The created record
        def to_queue(**attributes)
          Railbox::TransactionalOutboxMutator.create(**attributes)
        end
      end
    end
  end
end