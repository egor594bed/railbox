module Railbox
  module Processors
    class HandlerProcessor
      class << self

        def process(record)
          interface             = Railbox::TransactionalOutboxInterface.new(record)
          action_data           = record.action_data.deep_symbolize_keys!
          handler               = Object.const_get(action_data[:class_name])
          handler.outbox_entity = interface

          handler.public_send(action_data[:method_name])

          handler.outbox_entity = nil
        end
      end
    end
  end
end
