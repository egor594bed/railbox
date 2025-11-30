module Railbox
  module Processors
    class HandlerProcessor
      extend ActiveSupport::Concern

      class << self

        def process(record)
          with_handler(record) do |handler, action_data|
            handler.public_send(action_data[:method_name])
          end
        end

        def on_failure(record)
          with_handler(record) do |handler, _action_data|
            handler.on_failure
          end
        end

        private

        def with_handler(record)
          interface   = Railbox::TransactionalOutboxInterface.new(record)
          action_data = record.action_data
          handler     = Object.const_get(action_data[:class_name])

          handler.outbox_entity = interface

          yield(handler, action_data)
        ensure
          handler.outbox_entity = nil if handler
        end
      end
    end
  end
end
