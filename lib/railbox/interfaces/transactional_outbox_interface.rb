module Railbox
  class TransactionalOutboxInterface

    def initialize(record)
      @record = record
    end

    extend Forwardable
    def_delegators :@record,
                   :id, :action_type, :action_data, :status, :relative_entity,
                   :query, :body, :headers, :meta, :attempts, :retry_at, :failure_reasons,
                   :group
  end
end
